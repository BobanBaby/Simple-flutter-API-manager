import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_manager/service/ssl_pinning.dart';
import 'package:path_provider/path_provider.dart';

enum ErrorTypes {
  offline,
  timeout,
  failed,
  unknown,
  inValidResponse,
}

class NetworkServiceManager {
  static final NetworkServiceManager _networkServiceManager =
      NetworkServiceManager._NetworkServiceManager();
  static late HttpClient client;
  static late PersistCookieJar cookieJar;

  NetworkServiceManager._NetworkServiceManager();

//intialize network manager
  static Future<bool> init() async {
    try {
      var tempDir = await getTemporaryDirectory();
      var tempPath = tempDir.path;
      cookieJar =
          PersistCookieJar(ignoreExpires: true, storage: FileStorage(tempPath));
      //SSL Pinning
      var context = SecurityContext.defaultContext;
      context.setTrustedCertificatesBytes(CertificateByte.cert);
      client = HttpClient(context: context);
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        print('!!!!Bad certificate');
        return false;
      };
      return true;
    } catch (exception) {
      return false;
    }
  }

  factory NetworkServiceManager() {
    return _networkServiceManager;
  }

//To clear cookies list
  static Future clearCookies() async => cookieJar.deleteAll();

  static Future cGet({required String url}) async {
    var request = await client.getUrl(Uri.parse(url));
    var response = await _sendRequest(request, url);
    return response;
  }

  static Future callPost({required String url, @required requestData}) async {
    var request = await client.postUrl(Uri.parse(url));
    var response = await _sendRequest(request, url, requestData: requestData);
    return response;
  }

  static Future callPut(
      {required String url, @required var requestData}) async {
    var request = await client.putUrl(Uri.parse(url));
    var response = await _sendRequest(request, url, requestData: requestData);
    return response;
  }

  static Future _sendRequest(request, url, {var requestData}) async {
    request.headers.set('content-type', 'application/json');
    request.cookies.addAll(await cookieJar.loadForRequest(Uri.parse(url)));
    if (requestData != null) request.add(utf8.encode(json.encode(requestData)));

    try {
      var response = await request.close().timeout(Duration(seconds: 30));
      if (response != null) {
        await cookieJar.saveFromResponse(Uri.parse(url), response.cookies);
      }

      if (response.statusCode == 200) {
        final result = await response.transform(utf8.decoder).join();
        return jsonDecode(result);
      } else {
        throw ErrorTypes.failed;
      }
    } on TimeoutException catch (e) {
      print(e.message);
      throw ErrorTypes.timeout;
    } on FormatException catch (e) {
      print(e.message);
      throw ErrorTypes.inValidResponse;
    } on SocketException catch (e) {
      print(e.message);
      throw ErrorTypes.offline;
    } on ErrorTypes {
      rethrow;
    } on Error catch (e) {
      print(e.stackTrace);
      throw ErrorTypes.unknown;
    }
  }
}

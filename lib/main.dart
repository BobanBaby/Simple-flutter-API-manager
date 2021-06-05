import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Manager',
      home: Scaffold(
        appBar: AppBar(
          title: Text('API Demo App'),
        ),
        body: Center(
          child: Container(
            child: Text('Please refer services folder'),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AlertScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림 화면'),
      ),
      body: Center(
        child: Text('알림 화면 내용'),
      ),
    );
  }
}

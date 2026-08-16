import 'package:flutter/material.dart';
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            return Positioned(
              left: 50, top: 50,
              child: Text('Hello'),
            );
          }),
        ],
      ),
    ),
  ));
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DefaultErrorPage extends StatelessWidget {
  final String message;

  const DefaultErrorPage(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.red,
          ),
          maxLines: 4,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

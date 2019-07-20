import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gbera_framework/framework.dart';

class ErrorDispaly extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    Object arguments = ModalRoute.of(context).settings.arguments;
    String message = '';
    if (arguments != null && (arguments is Map<String, Object>)) {
      message = arguments['error'];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '这是微应用自定义的错误页',
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message,
                style: TextStyle(
                  color: Colors.red,
                ),
                maxLines: 4,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  final DisplayContext context;
  const ErrorDispaly({this.context});
}

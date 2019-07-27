//以下主页应放到主程序中实现并向framework注册s
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';

class BackdropDisplay extends StatefulWidget {
  BackdropDisplay({Key key, this.title, this.context}) : super(key: key);

  final DisplayContext context;
  final String title; //应用的标题，不是android任务栏状态时的标题

  @override
  _BackdropDisplayState createState() => _BackdropDisplayState();
}

class _BackdropDisplayState extends State<BackdropDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Text("....${widget.context.path()}"),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

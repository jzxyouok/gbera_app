import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../util.dart';

class ErrorPortal extends StatelessWidget {
  Widget errorPage;
  String taskbarTitle;
  ThemeData themeData;

  ErrorPortal({this.errorPage, this.taskbarTitle, this.themeData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:taskbarTitle ,
      theme: themeData,
      home: errorPage,
    );
  }
}

class DefaultErrorPage extends StatelessWidget {
  final String message;

  const DefaultErrorPage({this.message});

  @override
  Widget build(BuildContext context) {
    String msg=message;
    if(StringUtil.isEmpty(msg)){
      Object obj=ModalRoute.of(context).settings.arguments;
      if(obj!=null&&(obj is FlutterErrorDetails)){
       msg= obj.exceptionAsString();
      }
    }
    if(msg==null){
      msg='';
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Text(
                  '${ModalRoute.of(context).settings.name}',
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                msg,
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
}

//以下主页应放到主程序中实现并向framework注册s
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';

class GberaHomeDisplay extends StatefulWidget {

  GberaHomeDisplay({Key key, this.title,this.context}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final DisplayContext context;
  final String title; //应用的标题，不是android任务栏状态时的标题

  @override
  _GberaHomeDisplayState createState() => _GberaHomeDisplayState();
}

class _GberaHomeDisplayState extends State<GberaHomeDisplay> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Text("....${widget.context.path()}"),
              onPressed: (){
//                Navigator.pushNamed(context, 'gbera://dir1/dir2/page2.page');
                  print('当前页：'+widget.context.path());
                  widget.context.forward('gbera://dir1/dir2/page2.page');
              },

            ),
          ],
        ),
      ),
    );
  }
}
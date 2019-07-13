import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';
import 'package:yaml/yaml.dart';

class NetosApp extends StatefulWidget {
  // This widget is the root of your application.
  final String taskbarTitle;
  final String welcome; //主页路径
  final initFramework;

  @override
  _NetosAppState createState() => _NetosAppState();

  const NetosApp(
      {this.taskbarTitle,
      this.welcome,
      this.initFramework(Framework framework)});
}

class _NetosAppState extends State<NetosApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  /* 你看，它能支持全路径写法
  {
        "gbera://index.page": (context) => GberaHomePage(title: '金证时代'),
      },
   */
  @override
  Widget build(BuildContext context) {
    final framework = Framework.getFramework();
    widget.initFramework(framework);
    //MaterialApp是一个应用中唯一的根，切换微应用就是切换脚手架
    return MaterialApp(
//      title： 该标题出现在 Android：任务管理器的程序快照之上；IOS: 程序切换管理器中。经测试标题仅在android上有效
      title: widget.taskbarTitle ?? 'gbera',
//onGenerateTitle与title效果一样
//      onGenerateTitle: (context) {
//        return widget.taskbarTitle??'gbera';
//      },
      //同title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: widget.welcome,
      //初始化是官方主页地址
//      routes: framework.onOfficialMicroappRouters(context,widget.welcome),
      onGenerateRoute: framework.onUnofficialMicroappRouters,
      onUnknownRoute: framework.onUnknownRoute,
      //      onGenerateRoute: ,//在找不到路由时响应
//    onUnknownRoute: ,//未知路由，调用顺序为onGenerateRoute ==> onUnknownRoute
//    navigatorObservers: ,//导航观擦
//      home: GberaHomePage(title: 'Flutter Demo Home Page'),//home可注释掉而采用initialRoute作为首页，这样就统一为对路径的调用
    );
  }
}

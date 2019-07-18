import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';
import 'package:yaml/yaml.dart';

class NetosApp extends StatefulWidget {
  ///任务栏显示的标题
  final String taskbarTitle;
  Framework framework;
  ///登欢迎页
  final String welcome; //主页路径
  ///绑定微主题
  final bindThemes;
  @override
  _NetosAppState createState() => _NetosAppState();

   NetosApp({
    this.taskbarTitle,
    this.welcome,
    this.bindThemes(Framework framework),
  }):assert(welcome!=null),assert(taskbarTitle!=null),assert(bindThemes!=null){
    framework=Framework();
    bindThemes(framework);
  }
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
    Framework framework=widget.framework;
    //MaterialApp是一个应用中唯一的根，切换微应用就是切换脚手架
    return MaterialApp(
//      title： 该标题出现在 Android：任务管理器的程序快照之上；IOS: 程序切换管理器中。经测试标题仅在android上有效
      title: widget.taskbarTitle ?? 'gbera',
//onGenerateTitle与title效果一样
//      onGenerateTitle: (context) {
//        return widget.taskbarTitle??'gbera';
//      },
      //同title
      theme: framework.onRenderTheme(context),
      initialRoute: widget.welcome,
      //初始化是官方主页地址
//      routes: framework.onOfficialMicroappRouters(context,widget.welcome),
      onGenerateRoute: framework.onGenerateMicroappRouters,
//      onUnknownRoute: framework.onUnknownRoute,
      //      onGenerateRoute: ,//在找不到路由时响应
//    onUnknownRoute: ,//未知路由，调用顺序为onGenerateRoute ==> onUnknownRoute
//    navigatorObservers: ,//导航观擦
//      home: GberaHomePage(title: 'Flutter Demo Home Page'),//home可注释掉而采用initialRoute作为首页，这样就统一为对路径的调用
    );
  }
}

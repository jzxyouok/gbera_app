import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';


class NetosApp extends StatefulWidget implements IServiceProvider{
  ///任务栏显示的标题
  final String taskbarTitle;
  Framework framework;
  ///登欢迎页
  final String welcome; //主页路径
  final ThemeData themeData;
  @override
  _NetosAppState createState() => _NetosAppState();

  @override
  getService(String name) {
    if('@welcome'==name){
      return this.welcome;
    }
    return null;
  }

  NetosApp({
    this.taskbarTitle,
    this.welcome,
    this.framework,
    this.themeData,
  }):assert(welcome!=null&&welcome.lastIndexOf("://")>0),assert(taskbarTitle!=null);
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
      theme: widget.themeData,
      initialRoute: widget.welcome,
      onGenerateRoute: framework.onGenerateMicroappRouters,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gbera_framework/framework.dart';

import 'error_page.dart';

class NetosApp extends StatefulWidget implements IServiceProvider {
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
    if ('@welcome' == name) {
      return this.welcome;
    }
    return null;
  }

  NetosApp({
    this.taskbarTitle,
    this.welcome,
    this.framework,
    this.themeData,
  })  : assert(welcome != null && welcome.lastIndexOf("://") > 0),
        assert(taskbarTitle != null);
}

class _NetosAppState extends State<NetosApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Framework framework = widget.framework;
    return MaterialApp(
      title: widget.taskbarTitle ?? 'gbera',
      theme: widget.themeData,
      initialRoute: widget.welcome,
      onGenerateRoute: framework.onGenerateMicroappRouters,
      onUnknownRoute: framework.onUnknownRoute,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gbera_app/src/themes/gbera/versions/v-1.0/displays/home_display.dart';
import 'package:gbera_framework/gbera_app.dart';
import 'package:gbera_framework/framework.dart';
import 'dart:io';
import 'package:flutter/services.dart';

//flutter中的dart不支持动态反射实例化类型
//面向微主题开发，向framework注册微主题

void main() {

  if(Platform.isAndroid){
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor:Colors.transparent,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  framework.remote_updater = 'http://localhost:7800/microapp/updateManager.service';

  runApp(NetosApp(
    taskbarTitle: 'gbera',
    welcome: 'gbera://dir1/page1.page',
    initFramework: (framework) {
      framework.load(path: "src/conf");

      framework.themeBinder(
        theme: "mytheme/1.0",
        displays: (theme) {
          //懒构造显示器的函数参数：在此传入当前app,主题,及显示器，因此得弄个displayContext让开发者传入其自定义的显示器构造
          return {
            'display1': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay2': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay3': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay4': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
          };
        },
      );

      framework.themeBinder(
        theme: "mytheme/1.1",
        displays: (theme) {
          return {
            'mydisplay1': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay2': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay3': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
            'mydisplay4': (theme,display)=> GberaHomeDisplay(title: 'xxxx',),
          };
        },
      );
    },
  ));
}

library gbera;

import 'package:flutter/material.dart';
import 'package:gbera_app/src/themes/gbera/versions/v-1.0/displays/login_display.dart';
import 'package:gbera_framework/gbera_app.dart';
import 'package:gbera_framework/framework.dart';

import 'src/themes/gbera/versions/v-1.0/displays/backdrop_display.dart';

//flutter中的dart不支持动态反射实例化类型
//面向微主题开发，向framework注册微主题

void main() {
  runApp(NetosApp(
    taskbarTitle: 'gbera',
    welcome: 'gbera://public/login.page',
    bindThemes: (framework) {
      framework.initEnv(
        remoteMicroappHost: 'http://localhost:7800',
        clearCaches: true,
        oninit: (framework,context)async{
          print('......init');
        },
        onexit: (framework)async{
          print('.......exit');
        },
      );
      framework.themeBinder(
        theme: "gbera/1.0",
        displays: (theme) {
          //懒构造显示器的函数参数：在此传入当前app,主题,及显示器，因此得弄个displayContext让开发者传入其自定义的显示器构造
          return {
            'login_display': (context) => LoginDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'backdrop_display': (context) => BackdropDisplay(
                  context: context,
                  title: 'yyyy',
                ),
          };
        },
      );
    },
  ));
}

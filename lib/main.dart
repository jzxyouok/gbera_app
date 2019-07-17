library gbera;

import 'package:flutter/material.dart';
import 'package:gbera_app/src/themes/gbera/versions/v-1.0/displays/display1.dart';
import 'package:gbera_framework/gbera_app.dart';
import 'package:gbera_framework/framework.dart';

//flutter中的dart不支持动态反射实例化类型
//面向微主题开发，向framework注册微主题

void main() {

  runApp(NetosApp(
    taskbarTitle: 'gbera',
    welcome: 'gbera://dir1/page1.page',
    bindThemes: (framework) {
      framework.initEnv(remoteMicroappHost: 'http://localhost:7800');
      framework.themeBinder(
        theme: "gbera/1.0",
        displays: (theme) {
          //懒构造显示器的函数参数：在此传入当前app,主题,及显示器，因此得弄个displayContext让开发者传入其自定义的显示器构造
          return {
            'display1': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay2': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay3': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay4': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
          };
        },
      );

      framework.themeBinder(
        theme: "mytheme/1.1",
        displays: (theme) {
          return {
            'mydisplay1': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay2': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay3': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
            'mydisplay4': (context) => GberaHomeDisplay(
                  context: context,
                  title: 'xxxx',
                ),
          };
        },
      );
    },
  ));
}

import 'package:flutter/material.dart';
import 'package:gbera_app/src/microthemes/test.dart';
import 'package:gbera_framework/gbera_app.dart';
//面向微主题开发，向framework注册微主题
void main() => runApp(NetosApp(
      taskbarTitle: 'gbera',
      welcome: 'gbera://index.page',
      initFramework: (framework) {

        print('...$framework');
        class.runtimeType.noSuchMethod(invocation)
        framework.addMicroTheme({
          name: "mytheme",
          defaultStyle: "mystyle",
          version: "1.0",
          displays: [
            {
              "name": "",
              "widget": GberaHomePage(),//flutter中的dart不支持动态反射实例化类型
              "methods": [],
            }
          ],
          styles: [
            {},
          ]
        });
      },
    ));

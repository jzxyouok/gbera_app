import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'i_service.dart';
import 'package:yaml/yaml.dart';

class MicroappCacher implements IAppLocalCacher {
  String homeDir;

  @override
  Map<String, Object> getApp(String microapp) {
    return null;
  }

  //apps
  //-cctv
  //---versions
  //---v-1.0.json
  //---v-1.1.json
  //---data
  //-----xxx.text
  @override
  void putApp(Map<String, Object> app) {
    String json = jsonEncode(app);
    print(json);
    var dir = Directory("$homeDir/$app['name']");
    if (!dir.existsSync()) {
      dir.createSync();
    }
    File f = File('$homeDir/');
  }

  @override
  void init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    homeDir = '${appDocDir.path}/apps';
  }

  @override
  void dispose() {}
}

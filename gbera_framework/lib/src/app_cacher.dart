import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'i_service.dart';
import 'package:yaml/yaml.dart';

import 'util.dart';

class MicroappCacher implements IAppLocalCacher {
  String homeDir;

  @override
  Map<String, Object> getApp(String microapp) {
    var dir = Directory("$homeDir");
    if (!dir.existsSync()) {
      return null;
    }

    String fn='${homeDir}/${microapp}/app.json';
    var f=File(fn);
    if(!f.existsSync()){
      return null;
    }
    String json=f.readAsStringSync();
    var obj= jsonDecode(json);
    return obj;
  }

  //apps
  //-cctv
  //---app.json #一个应用仅保存一个在用版本
  //---data
  //-----xxx.text
  @override
  void putApp(Map<String, Object> app) {
    String json = jsonEncode(app);
    var dir = Directory("$homeDir/${app['name']}");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File f = File("${dir.path}/app.json");
    f.openSync(mode: FileMode.write);
    f.writeAsStringSync(json);
  }

  @override
  void init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    homeDir = '${appDocDir.path}/apps';
  }

  @override
  void dispose() {}
}

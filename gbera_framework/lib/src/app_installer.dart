import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gbera_framework/framework.dart';
import 'package:path_provider/path_provider.dart';

import 'i_service.dart';

///安装策略：
///1。启动时对于首页所在应用，检测本地是否存在，不存在则自动安装
///2。用户到应用市场安装
///3。当操作时连接到本地不存在的应用时则提示用户安装
class AppInstaller implements IAppInstaller {
  final IServiceProvider site;
  String _homeDir;

  AppInstaller(this.site);

  @override
  init() async {
    Directory docDir = await getApplicationDocumentsDirectory();
    _homeDir = '${docDir.path}/system';
  }

  @override
  Future installApp(String appname) async {
    var app = await _findApp(appname);
    var portal = await _findPortal(app['portal']);
    //覆盖安装，一个app只安装一个（谁见过手机端装一个应用的多个版的？所以微应用也是这样）
    await _saveApp(app);
    await _savePortal(portal);
  }

  _findApp(String appname) async {
    Dio http = site.getService("@http");
    try {
      String remote = site.getService("@remote.searcher");
      String remoteMicroappToken = site.getService('@remoteMicroappToken');
      Options options = Options(headers: {
        'Rest-Command': 'getMicroAppInfo',
        'cjtoken':remoteMicroappToken
      });
      Response response = await http.get(
        remote,
        queryParameters: {'microapp': appname},
        options: options,
      );
      String text = response.data.toString();
      Map<String,Object> rc = json.decode(text);
      if(rc['status']!=200){
        throw Future.error('访问微应用服务器出错');
      }
      var app=json.decode(rc['dataText']);
      return app;
    } catch (e) {
      throw e;
    }
  }

  _findPortal(String portal) async {
    Dio http = site.getService("@http");
    try {
      String remote = site.getService("@remote.searcher");
      String remoteMicroappToken = site.getService('@remoteMicroappToken');
      Options options = Options(headers: {
        'Rest-Command': 'getMicroPortalInfo',
        'cjtoken':remoteMicroappToken
      });
      Response response = await http.get(
        remote,
        queryParameters: {'microportal': portal},
        options: options,
      );
      String text = response.data.toString();
      Map<String,Object> rc = json.decode(text);
      if(rc['status']!=200){
        throw Future.error('访问微应用服务器出错');
      }
      var portalInfo = json.decode(rc['dataText']);
      return portalInfo;
    } catch (e) {
      throw e;
    }
  }

  _saveApp(app) async {
    String json = jsonEncode(app);
    var dir = Directory("$_homeDir/apps/${app['name']}");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File f = File("${dir.path}/app.json");
    f.openSync(mode: FileMode.write);
    f.writeAsStringSync(json);
  }

  _savePortal(portal) async {
    String json = jsonEncode(portal);
    var dir = Directory("$_homeDir/portals/${portal['name']}");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File f = File("${dir.path}/portal-${portal['version']}.json");
    f.openSync(mode: FileMode.write);
    f.writeAsStringSync(json);
  }
}

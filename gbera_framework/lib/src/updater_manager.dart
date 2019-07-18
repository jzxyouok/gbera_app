import 'dart:io';

import 'app_cacher.dart';
import 'i_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class UpdateManager implements IUpdateManager {
  IServiceProvider site;
  IAppLocalCacher _appLocalCacher;
  UpdateManager(this.site) {
    _appLocalCacher=MicroappCacher();
    _appLocalCacher.init();
  }

  @override
  getMicroApp(String microapp, {onsuccess, onerror}) async {
    dynamic app=_appLocalCacher.getApp(microapp);
    if(app!=null&&onsuccess!=null){
      onsuccess(app);
      return ;
    }
    Dio http = site.getService("@http");
    try {
      String remote = site.getService("@remote.updater");
      Options options = Options(headers: {
        'Rest-StubFace': 'cj.netos.microapp.stub.IGberaUpdateManager',
        'Rest-Command': 'getMicroApp'
      });
      Response response = await http.get(
        remote,
        queryParameters: {'microappname': microapp},
        options: options,
      );
      String text=response.data.toString();
      app=json.decode(text);

      _appLocalCacher.putApp(app);
      if (onsuccess != null) {
        onsuccess(app);
      }
    } catch (e) {
      print(e);
      if (onerror != null) {
        onerror(e);
      }
    }
  }
}

import 'i_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class UpdateManager implements IUpdateManager {
  IServiceProvider site;
  Map<String, Map<String,Object>> _appCacher;//key是app名，为什么不用appname/version呢，是因为缓冲器仅缓冲当前使用的一个版本

  UpdateManager(this.site) {
    _appCacher = Map();
  }

  @override
  getMicroApp(String microapp, {onsuccess, onerror}) async {
    dynamic app=_appCacher[microapp];
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
      _appCacher[app['name']]=app;
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

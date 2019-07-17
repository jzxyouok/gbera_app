import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

mixin IServiceProvider {
  getService(String name);
}

typedef onSuccess = Function(Map<String, Object> app);
typedef onError = Function(dynamic err);
mixin IUpdateManager {
  Future getMicroApp(String microapp, {onSuccess onsuccess, onError onerror});
}

///本地缓冲
///为什么不用appname/version呢，是因为缓冲器仅缓冲当前使用的一个版本
mixin IAppLocalCacher {
  void init();

  void dispose();

  Map<String, Object> getApp(String microapp);

  void putApp(Map<String, Object> app);
}

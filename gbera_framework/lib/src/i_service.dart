import 'package:dio/dio.dart';


mixin IServiceProvider {
  getService(String name);
}

typedef onSuccess = Function(Map<String,Object> app);
typedef onError = Function(dynamic err);
mixin IUpdateManager {
  Future getMicroApp(String microapp,{onSuccess onsuccess,onError onerror});
}

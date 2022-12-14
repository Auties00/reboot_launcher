import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jaguar/jaguar.dart';

import '../model/server_type.dart';

class ServerController extends GetxController {
  static const String _serverName = "127.0.0.1";
  static const String _serverPort = "3551";

  late final GetStorage _storage;
  late final TextEditingController host;
  late final TextEditingController port;
  late final Rx<ServerType> type;
  late final RxBool warning;
  late RxBool started;
  Jaguar? embeddedServer;
  Jaguar? embeddedMatchmaker;
  HttpServer? remoteServer;

  ServerController() {
    _storage = GetStorage("server");

    type = Rx(ServerType.values.elementAt(_storage.read("type") ?? 0));
    type.listen((value) {
      host.text = _readHost();
      port.text = _readPort();
      _storage.write("type", value.index);

      if(!started.value) {
        return;
      }

      if(value == ServerType.remote){
        remoteServer?.close(force: true);
        remoteServer = null;
        started.value = false;
        return;
      }

      stop();
    });

    host = TextEditingController(text: _readHost());
    host.addListener(() => _storage.write("${type.value.id}_host", host.text));

    port = TextEditingController(text: _readPort());
    port.addListener(() => _storage.write("${type.value.id}_port", port.text));

    warning = RxBool(_storage.read("lawin_value") ?? true);
    warning.listen((value) => _storage.write("lawin_value", value));

    started = RxBool(false);
  }

  String _readHost() {
    String? value = _storage.read("${type.value.id}_host");
    return value != null && value.isNotEmpty ? value
        : type.value != ServerType.remote ? _serverName : "";
  }

  String _readPort() {
    return _storage.read("${type.value.id}_port") ?? _serverPort;
  }

  Future<bool> stop() async {
    started.value = false;
    try{
      switch(type()){
        case ServerType.embedded:
          await embeddedServer?.close();
          await embeddedMatchmaker?.close();
          break;
        case ServerType.remote:
          await remoteServer?.close(force: true);
          break;
        case ServerType.local:
          break;
      }
      return true;
    }catch(_){
      started.value = true;
      return false;
    }
  }
}
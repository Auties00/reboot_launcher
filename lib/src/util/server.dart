import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:reboot_launcher/src/model/game_type.dart';
import 'package:reboot_launcher/src/model/server_type.dart';
import 'package:reboot_launcher/src/util/os.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf/shelf_io.dart';

final serverLogFile = File("${Platform.environment["UserProfile"]}\\.reboot_launcher\\server.txt");

Future<bool> isLawinPortFree() async {
  try {
    var portBat = await loadBinary("port.bat", true);
    var process = await Process.run(portBat.path, []);
    return !process.outText.contains(" LISTENING ");
  }catch(_){
    return ServerSocket.bind("127.0.0.1", 3551)
        .then((socket) => socket.close())
        .then((_) => true)
        .onError((error, _) => false);
  }
}

Future<void> freeLawinPort() async {
  var releaseBat = await loadBinary("release.bat", false);
  var result = await Process.run(releaseBat.path, []);
  if(!result.outText.contains("Access is denied")){
    return;
  }

  await runElevated(releaseBat.path, "");
}

List<String> createRebootArgs(String username, GameType type) {
  var args = [
    "-epicapp=Fortnite",
    "-epicenv=Prod",
    "-epiclocale=en-us",
    "-epicportal",
    "-skippatchcheck",
    "-nobe",
    "-fromfl=eac",
    "-fltoken=3db3ba5dcbd2e16703f3978d",
    "-caldera=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50X2lkIjoiYmU5ZGE1YzJmYmVhNDQwN2IyZjQwZWJhYWQ4NTlhZDQiLCJnZW5lcmF0ZWQiOjE2Mzg3MTcyNzgsImNhbGRlcmFHdWlkIjoiMzgxMGI4NjMtMmE2NS00NDU3LTliNTgtNGRhYjNiNDgyYTg2IiwiYWNQcm92aWRlciI6IkVhc3lBbnRpQ2hlYXQiLCJub3RlcyI6IiIsImZhbGxiYWNrIjpmYWxzZX0.VAWQB67RTxhiWOxx7DBjnzDnXyyEnX7OljJm-j2d88G_WgwQ9wrE6lwMEHZHjBd1ISJdUO1UVUqkfLdU5nofBQ"
  ];

  if(username.isNotEmpty){
    args.addAll([
      "-AUTH_LOGIN=${username.replaceAll(RegExp("[^A-Za-z0-9]"), "")}@projectreboot.dev",
      "-AUTH_PASSWORD=Rebooted",
      "-AUTH_TYPE=epic"
    ]);
  }

  if(type == GameType.headlessServer){
    args.addAll([
      "-nullrhi",
      "-nosplash",
      "-nosound",
    ]);
  }

  return args;
}

Future<Uri?> pingSelf(String port) async => ping("127.0.0.1", port);

Future<Uri?> ping(String host, String port, [bool https=false]) async {
  var hostName = _getHostName(host);
  var declaredScheme = _getScheme(host);
  try{
    var uri = Uri(
        scheme: declaredScheme ?? (https ? "https" : "http"),
        host: hostName,
        port: int.parse(port),
        path: "unknown"
    );
    var client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    var request = await client.getUrl(uri);
    var response = await request.close();
    var body = utf8.decode(await response.single);
    return body.contains("epicgames") || body.contains("lawinserver") ? uri : null;
  }catch(_){
    return https || declaredScheme != null ? null : await ping(host, port, true);
  }
}

String? _getHostName(String host) => host.replaceFirst("http://", "").replaceFirst("https://", "");

String? _getScheme(String host) => host.startsWith("http://") ? "http" : host.startsWith("https://") ? "https" : null;

Future<ServerResult> checkServerPreconditions(String host, String port, ServerType type, bool needsFreePort) async {
  host = host.trim();
  if(host.isEmpty){
    return ServerResult(
        type: ServerResultType.missingHostError
    );
  }

  port = port.trim();
  if(port.isEmpty){
    return ServerResult(
        type: ServerResultType.missingPortError
    );
  }

  if(int.tryParse(port) == null){
    return ServerResult(
        type: ServerResultType.illegalPortError
    );
  }

  if(type == ServerType.embedded || type == ServerType.remote){
    var free = await isLawinPortFree();
    if (!free) {
      if(!needsFreePort) {
        return ServerResult(
            type: ServerResultType.alreadyStarted
        );
      }

      return ServerResult(
          type: ServerResultType.portTakenError
      );
    }
  }

  return ServerResult(
      type: ServerResultType.canStart
  );
}

Future<HttpServer> startRemoteServer(Uri uri) async {
  return await serve(proxyHandler(uri), "127.0.0.1", 3551);
}

class ServerResult {
  final int? pid;
  final Object? error;
  final StackTrace? stackTrace;
  final ServerResultType type;

  ServerResult({this.pid, this.error, this.stackTrace, required this.type});
}

enum ServerResultType {
  missingHostError,
  missingPortError,
  illegalPortError,
  cannotPingServer,
  portTakenError,
  canStart,
  alreadyStarted,
  unknownError,
  stopped,
}
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:get_storage/get_storage.dart';
import 'package:reboot_launcher/src/util/binary.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rebootUrl =
    "https://nightly.link/UWUFN/Universal-Walking-Simulator/workflows/msbuild/master/Release.zip";
final GetStorage _storage = GetStorage("update");

Future<DateTime?> _getLastUpdate() async {
  int? timeInMillis = _storage.read("last_update");
  return timeInMillis != null ? DateTime.fromMillisecondsSinceEpoch(timeInMillis) : null;
}

Future<File> downloadRebootDll() async {
  var now = DateTime.now();
  var oldRebootDll = await loadBinary("reboot.dll", true);
  var lastUpdate = await _getLastUpdate();
  var exists = await oldRebootDll.exists();
  if(lastUpdate != null && now.difference(lastUpdate).inHours <= 24 && exists){
    return oldRebootDll;
  }

  var response = await http.get(Uri.parse(_rebootUrl));
  var tempZip = File("${Platform.environment["Temp"]}/reboot.zip");
  await tempZip.writeAsBytes(response.bodyBytes);
  await extractFileToDisk(tempZip.path, safeBinariesDirectory);
  var pdb = await loadBinary("Project Reboot.pdb", true);
  pdb.delete();
  var rebootDll = await loadBinary("Project Reboot.dll", true);
  if (!(await rebootDll.exists())) {
    throw Exception("Missing reboot dll");
  }

  _storage.write("last_update", now.millisecondsSinceEpoch);
  if (exists && sha1.convert(await oldRebootDll.readAsBytes()) == sha1.convert(await rebootDll.readAsBytes())) {
    rebootDll.delete();
    return oldRebootDll;
  }

  await rebootDll.rename(oldRebootDll.path);
  return oldRebootDll;
}

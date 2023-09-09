
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:reboot_common/common.dart';
import 'package:reboot_launcher/src/controller/hosting_controller.dart';
import 'package:reboot_launcher/src/controller/matchmaker_controller.dart';
import 'package:reboot_launcher/src/page/home_page.dart';
import 'package:reboot_launcher/src/widget/common/setting_tile.dart';
import 'package:reboot_launcher/src/widget/game/start_button.dart';
import 'package:reboot_launcher/src/widget/version/version_selector.dart';


class PlayPage extends StatefulWidget {
  const PlayPage({Key? key}) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final MatchmakerController _matchmakerController = Get.find<MatchmakerController>();
  final HostingController _hostingController = Get.find<HostingController>();
  late final RxBool _selfServer;

  @override
  void initState() {
    _selfServer = RxBool(_isLocalPlay);
    _matchmakerController.gameServerAddress.addListener(() => _selfServer.value = _isLocalPlay);
    _hostingController.started.listen((_) => _selfServer.value = _isLocalPlay);
    super.initState();
  }

  bool get _isLocalPlay => isLocalHost(_matchmakerController.gameServerAddress.text)
      && !_hostingController.started.value;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Expanded(
              child: ListView(
                children: [
                  const SettingTile(
                      title: "Version",
                      subtitle: "Select the version of Fortnite you want to host",
                      content: VersionSelector(),
                      expandedContent: [
                        SettingTile(
                            title: "Add a version from this PC's local storage",
                            subtitle: "Versions coming from your local disk are not guaranteed to work",
                            content: Button(
                              onPressed: VersionSelector.openAddDialog,
                              child: Text("Add build"),
                            ),
                            isChild: true
                        ),
                        SettingTile(
                            title: "Download any version from the cloud",
                            subtitle: "Download any Fortnite build easily from the cloud",
                            content: Button(
                              onPressed: VersionSelector.openDownloadDialog,
                              child: Text("Download"),
                            ),
                            isChild: true
                        )
                      ]
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  SettingTile(
                      title: "Game Server",
                      subtitle: "Helpful shortcuts to find the server where you want to play",
                      content: IgnorePointer(
                        child: Button(
                            style: ButtonStyle(
                                backgroundColor: ButtonState.all(FluentTheme.of(context).resources.controlFillColorDefault)
                            ),
                            onPressed: () {},
                            child: Obx(() {
                              var address = _matchmakerController.gameServerAddress.text;
                              var owner = _matchmakerController.gameServerOwner.value;
                              return Text(
                                isLocalHost(address) ? "Your server" : owner != null ? "$owner's server" : address,
                                textAlign: TextAlign.start
                            );
                            })
                        ),
                      ),
                      expandedContent: [
                        SettingTile(
                            title: "Host a server",
                            subtitle: "Do you want to create a game server for yourself or your friends? Host one!",
                            content: Button(
                                onPressed: () => pageIndex.value = 1,
                                child: const Text("Host")
                            ),
                            isChild: true
                        ),
                        SettingTile(
                            title: "Join a Reboot server",
                            subtitle: "Find a discoverable server hosted on the Reboot Launcher in the server browser",
                            content: Button(
                                onPressed: () => pageIndex.value = 2,
                                child: const Text("Browse")
                            ),
                            isChild: true
                        ),
                        SettingTile(
                            title: "Join a custom server",
                            subtitle: "Type the address of any server, whether it was hosted on the Reboot Launcher or not",
                            content: Button(
                                onPressed: () {
                                  pageIndex.value = 4;
                                  WidgetsBinding.instance.addPostFrameCallback((_) => _matchmakerController.gameServerAddressFocusNode.requestFocus());
                                },
                                child: const Text("Join")
                            ),
                            isChild: true
                        )
                      ]
                  ),
                ],
              )
          ),
          const SizedBox(
            height: 8.0,
          ),
          const LaunchButton(
              startLabel: 'Launch Fortnite',
              stopLabel: 'Close Fortnite',
              host: false
          )
        ]
    );
  }
}
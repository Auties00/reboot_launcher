import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:reboot_launcher/src/dialog/snackbar.dart';

import 'package:reboot_launcher/src/util/selector.dart';

class FileSelector extends StatefulWidget {
  final String label;
  final String placeholder;
  final String windowTitle;
  final bool allowNavigator;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final AutovalidateMode? validatorMode;
  final String? extension;
  final bool folder;

  const FileSelector(
      {required this.label,
        required this.placeholder,
        required this.windowTitle,
        required this.controller,
        required this.validator,
        required this.folder,
        this.extension,
        this.validatorMode,
        this.allowNavigator = true,
        Key? key})
      : assert(folder || extension != null, "Missing extension for file selector"),
        super(key: key);

  @override
  State<FileSelector> createState() => _FileSelectorState();
}

class _FileSelectorState extends State<FileSelector> {
  final RxBool _valid = RxBool(true);
  late String? Function(String?) validator;
  bool _selecting = false;

  @override
  void initState() {
    validator = (value) {
      var result = widget.validator(value);
      WidgetsBinding.instance.addPostFrameCallback((_) => _valid.value = result == null);
      return result;
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InfoLabel(
        label: widget.label,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: TextFormBox(
                  controller: widget.controller,
                  placeholder: widget.placeholder,
                  validator: validator,
                  autovalidateMode: widget.validatorMode ?? AutovalidateMode.onUserInteraction
                )
            ),
            if (widget.allowNavigator) const SizedBox(width: 8.0),
            if (widget.allowNavigator)
              Tooltip(
                  message: "Select a ${widget.folder ? 'folder' : 'file'}",
                  child: Obx(() => Padding(
                      padding: _valid() ? EdgeInsets.zero : const EdgeInsets.only(bottom: 21.0),
                      child: Button(
                          onPressed: _onPressed,
                          child: const Icon(FluentIcons.open_folder_horizontal)
                      ))
                  )
              )
          ],
        )
    );
  }

  void _onPressed() {
    if(_selecting){
      showMessage("Folder selector is already opened");
      return;
    }

    _selecting = true;
    if(widget.folder) {
      compute(openFolderPicker, widget.windowTitle)
          .then((value) => widget.controller.text = value ?? widget.controller.text)
          .then((_) => _selecting = false);
      return;
    }

    compute(openFilePicker, widget.extension!)
        .then((value) => widget.controller.text = value ?? widget.controller.text)
        .then((_) => _selecting = false);
  }
}
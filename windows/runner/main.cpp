#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
auto bdw = bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"
#include <iostream>
#include <io.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>

bool CheckOneInstance()
{
    HANDLE m_hStartEvent = CreateEventW( NULL, FALSE, FALSE, L"reboot_launcher");
    if(m_hStartEvent == NULL)
    {
        CloseHandle( m_hStartEvent );
        return false;
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS)
    {
        CloseHandle( m_hStartEvent );
        m_hStartEvent = NULL;
        return false;
    }

    return true;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if(!CheckOneInstance()){
    return false;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow(L"reboot_launcher", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

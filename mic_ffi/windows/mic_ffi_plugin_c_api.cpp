#include "include/mic_ffi/mic_ffi_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mic_ffi_plugin.h"

void MicFfiPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mic_ffi::MicFfiPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

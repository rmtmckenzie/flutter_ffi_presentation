//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <mic_ffi/mic_ffi_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) mic_ffi_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MicFfiPlugin");
  mic_ffi_plugin_register_with_registrar(mic_ffi_registrar);
}

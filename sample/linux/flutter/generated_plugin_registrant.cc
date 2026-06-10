//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <permission_plus_linux/permission_plus_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) permission_plus_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PermissionPlusLinuxPlugin");
  permission_plus_linux_plugin_register_with_registrar(permission_plus_linux_registrar);
}

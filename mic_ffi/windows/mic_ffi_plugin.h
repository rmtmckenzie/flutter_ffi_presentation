#ifndef FLUTTER_PLUGIN_MIC_FFI_PLUGIN_H_
#define FLUTTER_PLUGIN_MIC_FFI_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace mic_ffi {

class MicFfiPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MicFfiPlugin();

  virtual ~MicFfiPlugin();

  // Disallow copy and assign.
  MicFfiPlugin(const MicFfiPlugin&) = delete;
  MicFfiPlugin& operator=(const MicFfiPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mic_ffi

#endif  // FLUTTER_PLUGIN_MIC_FFI_PLUGIN_H_

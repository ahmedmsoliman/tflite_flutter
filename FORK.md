# About this fork

`tflite_flutter` 0.12.1 ([tensorflow/flutter-tflite@85fb92e](https://github.com/tensorflow/flutter-tflite/commit/85fb92ec)) with one change: on iOS the plugin depends on `TensorFlowLiteC/Core` instead of `TensorFlowLiteSwift`. Everything else, including the Dart API and Android, is unchanged.

Used by `didc`, which reaches native apps through the `h` Flutter module.

## Why

The plugin calls TensorFlow Lite through `dart:ffi` only (`DynamicLibrary.process()`), so the C library is all it needs. Upstream depends on `TensorFlowLiteSwift` 2.12.0, which causes three problems in host apps:

- **`pod install` clones all of TensorFlow.** The pod's source is a git commit of `tensorflow/tensorflow`, which CocoaPods cannot fetch shallowly, so it clones about 1.3 GB of history for a few Swift files this plugin never calls. On a cold machine this takes over an hour. `TensorFlowLiteC` is a prebuilt binary download of the same 2.12.0 library.
- **The link fails in an Objective-C-only app.** `TensorFlowLiteSwift` is a static Swift pod with a minimum of iOS 11, so it needs the `swiftCompatibility*` libraries, which Xcode links only when the app itself contains Swift (`Undefined symbol: __swift_FORCE_LOAD_$_swiftCompatibility50`).
- **Simulator architecture conflict.** The pod is one of several asking the host for conflicting `EXCLUDED_ARCHS[sdk=iphonesimulator*]` values. `TensorFlowLiteC` still asks for `i386`, so this warning remains when MLKit is also present.

## What changes for users of the plugin

- Only `TensorFlowLiteC/Core` is linked. The Metal and CoreML delegates are not, so `GpuDelegate` and `CoreMlDelegate` are unavailable on iOS. To use one, add `TensorFlowLiteC/Metal` or `TensorFlowLiteC/CoreML` to `ios/tflite_flutter.podspec`.
- The binary exports all 154 `TfLite*` symbols of the core library, the same set as before minus `TfLiteCoreMlDelegateCreate`/`Delete`.
- The app still needs **Strip Style: Non-Global Symbols** on release builds, because the symbols are looked up by name.

## Tags

`0.12.1-h.N` is upstream 0.12.1 plus this fork's changes. Pin a tag, never `main`.

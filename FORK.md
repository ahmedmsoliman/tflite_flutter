# About this fork

`tflite_flutter` 0.12.1 ([tensorflow/flutter-tflite@85fb92e](https://github.com/tensorflow/flutter-tflite/commit/85fb92ec)) with one change: on iOS the plugin bundles the TensorFlow Lite C library itself instead of depending on `TensorFlowLiteSwift`. Everything else, including the Dart API and Android, is unchanged.

Used by `didc`, which reaches native apps through the `h` Flutter module.

## Why

The plugin calls TensorFlow Lite through `dart:ffi` only (`DynamicLibrary.process()`), so the C library is all it needs. Upstream depends on `TensorFlowLiteSwift` 2.12.0, which causes three problems in host apps:

- **`pod install` clones all of TensorFlow.** The pod's source is a git commit of `tensorflow/tensorflow`, which CocoaPods cannot fetch shallowly, so it clones about 1.3 GB of history for a few Swift files this plugin never calls. On a cold machine this takes over an hour.
- **The link fails in an Objective-C-only app.** `TensorFlowLiteSwift` is a static Swift pod with a minimum of iOS 11, so it needs the `swiftCompatibility*` libraries, which Xcode links only when the app itself contains Swift (`Undefined symbol: __swift_FORCE_LOAD_$_swiftCompatibility50`).
- **Simulator builds fail next to MLKit.** The `TensorFlowLiteC` pod sets the host's `EXCLUDED_ARCHS[sdk=iphonesimulator*]` to `i386`, while MLKit sets it to `arm64`. CocoaPods cannot merge the two and applies neither, so a simulator build links MLKit's device-only `arm64` slice and fails (`building for 'iOS-simulator', but linking in object file ... MLImage[arm64]`).

Depending on the `TensorFlowLiteC` pod directly would fix the first two problems but not the third. So the framework is vendored, and a vendored framework sets nothing on the host.

## The bundled framework

`ios/Frameworks/TensorFlowLiteC.xcframework` is the **Core** framework of `TensorFlowLiteC` 2.12.0, unmodified. It comes from the same archive the `TensorFlowLiteC` pod downloads:

```
https://dl.google.com/tflite-release/ios/prod/tensorflow/lite/release/ios/release/25/20230414-162712/TensorFlowLiteC/2.12.0/bf93fad9a2465150/TensorFlowLiteC-2.12.0.tar.gz
sha256 88e623a406e06c3bec43ff61637a19a6381dff3031f39f96d00e2be8917bf8cb
```

| Binary | sha256 |
|---|---|
| `ios-arm64/TensorFlowLiteC.framework/TensorFlowLiteC` | `d57db1be4d722fea6023efd338b8ea218533b4ec38abeacda186c0428ebf419a` |
| `ios-arm64_x86_64-simulator/TensorFlowLiteC.framework/TensorFlowLiteC` | `68b7a86f26dbf9e43ec4f4050321e72015a6a69c1abc588a24c01a752593f111` |

TensorFlow is licensed under Apache 2.0, the same license as this plugin.

## What changes for users of the plugin

- Only the core library is included. The Metal and CoreML delegates are not, so `GpuDelegate` and `CoreMlDelegate` are unavailable on iOS.
- The binary exports all 154 `TfLite*` symbols of the core library, the same set as before minus `TfLiteCoreMlDelegateCreate`/`Delete`. Each binary is a single prelinked object, so the linker always takes it whole.
- The app still needs **Strip Style: Non-Global Symbols** on release builds, because the symbols are looked up by name.

## Updating TensorFlow Lite

Download the `TensorFlowLiteC` archive for the new version (its URL is in that version's podspec on the CocoaPods trunk). Replace `ios/Frameworks/TensorFlowLiteC.xcframework` with its `Frameworks/TensorFlowLiteC.xcframework`, update the checksums above, and tag a new `-h.N`.

## Tags

`0.12.1-h.N` is upstream 0.12.1 plus this fork's changes. Pin a tag, never `main`.

- `0.12.1-h.1`: depends on the `TensorFlowLiteC/Core` pod. Fixes the clone and the link failure, but not simulator builds next to MLKit.
- `0.12.1-h.2`: bundles the core framework. Fixes all three.

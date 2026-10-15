#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tflite_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tflite_flutter'
  s.version          = '0.0.1'
  s.summary          = 'TensorFlow Lite plugin for Flutter apps.'
  s.description      = <<-DESC
TensorFlow Lite plugin for Flutter apps.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  # s.source_files = 'Classes/**/*'
  
  s.dependency 'Flutter'
  
  # The plugin reaches TensorFlow Lite through dart:ffi only, so it needs the
  # C library and nothing else. Upstream depends on TensorFlowLiteSwift, whose
  # source is a git commit of tensorflow/tensorflow: `pod install` clones the
  # whole repository (~1.3 GB) for Swift files this plugin never calls, and the
  # static Swift pod at iOS 11 fails to link into an Objective-C-only Runner.
  #
  # The C library is vendored here instead of depending on the TensorFlowLiteC
  # pod, because that pod sets the host app's
  # EXCLUDED_ARCHS[sdk=iphonesimulator*] to i386 while MLKit sets arm64.
  # CocoaPods then applies neither, and the host's simulator build fails to
  # link MLKit's device-only arm64 slice. A vendored framework sets nothing on
  # the host.
  #
  # Frameworks/TensorFlowLiteC.xcframework is the unmodified Core framework of
  # TensorFlowLiteC 2.12.0, the same download the pod uses. See FORK.md for the
  # source URL and checksums. Metal and CoreML delegates are not included, so
  # GpuDelegate and CoreMlDelegate are unavailable on iOS.
  s.vendored_frameworks = 'Frameworks/TensorFlowLiteC.xcframework'
  s.library = 'c++'

  s.platform = :ios, '11.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

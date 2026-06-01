Pod::Spec.new do |s|
  s.name             = 'in_app_update_me'
  s.version          = '1.2.0'
  s.summary          = 'A Flutter plugin for in-app updates supporting both Android and iOS.'
  s.description      = <<-DESC
A Flutter plugin that provides in-app update capabilities for both Android and iOS platforms with direct update functionality and force update handling.
                       DESC
  s.homepage         = 'https://github.com/flutterLK/in_app_update_me'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'flutterLK' => 'flutterLK@github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

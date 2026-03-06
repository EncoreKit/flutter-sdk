Pod::Spec.new do |s|
  s.name             = 'encore'
  s.version          = '1.0.5'
  s.summary          = 'Flutter plugin wrapping the native Encore iOS SDK.'
  s.description      = 'Bridges the Encore iOS SDK (EncoreKit) to Flutter via platform channels.'
  s.homepage         = 'https://github.com/EncoreKit/encore-flutter-sdk'
  s.author           = { 'Encore' => 'support@encorekit.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'EncoreKit'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end

Pod::Spec.new do |s|
  s.name             = 'nefta_sdk_flutter'
  s.version          = '4.3.3'
  s.summary          = 'Nefta Flutter Plugin.'
  s.description      = <<-DESC
Nefta Flutter Plugin.
                       DESC
  s.homepage         = 'http://nefta.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nefta' => 'treven@nefta.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'NeftaSDK', '4.3.2'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

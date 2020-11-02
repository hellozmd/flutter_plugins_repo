#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mbc_push.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mbc_push'
  s.version          = '0.0.1'
  s.summary          = 'MBC push kit for flutter plugin'
  s.description      = <<-DESC
MBC push kit for flutter plugin
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AFNetworking', '~> 4.0'
  s.dependency 'UICKeyChainStore', '~> 2.2.1'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
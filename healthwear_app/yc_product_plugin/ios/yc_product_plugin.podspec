#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint yc_product_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'yc_product_plugin'
  s.version          = '0.0.1'
  s.summary          = 'flutter plugin project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }

  # 源代码的位置
  s.source_files = 'Classes/**/*'

  # 依赖框架
  # 这里如果多个写在一起是用空格分开不是逗号
  # s.dependency 'Flutter' 'B' 'C'
  # 也可以一个一个写
  # 一行写一个依赖

  s.dependency 'Flutter'
  


  # 设备运行平台
  s.platform = :ios, '11.0'

  # 本地的framework
  # Frameworks要和你创建的目录相同名称
  # 如果这里分开写用逗号分开如 'Frameworks/a.framework', 'Frameworks.b.framework', ...
  s.vendored_frameworks = [
    'Frameworks/*.framework',   # 匹配所有.framework文件
    'Frameworks/*.xcframework'  # 匹配所有.xcframework文件
  ]

  s.dependency 'iOSDFULibrary'	, '~> 4.13.0'

  # 不支持模拟器
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # Swift语言版本
  s.swift_version = '5.0'

  # 使用静态库
  s.static_framework = true

end

#
# Be sure to run `pod lib lint HHNetworkHelper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HHNetworkHelper'
  s.version          = '1.0.1'
  s.summary          = '封装AFNetwork4.0工具，YYCache缓存'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  封装AFNetwork4.0工具，YYCache缓存，实现GET，POST缓存请求，上传文件，下载文件，多张图片上传
                       DESC

  s.homepage         = 'https://github.com/hutaol/HHNetworkHelper'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Henry' => '1325049637@qq.com' }
  s.source           = { :git => 'https://github.com/hutaol/HHNetworkHelper.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'HHNetworkHelper/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HHNetworkHelper' => ['HHNetworkHelper/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 4.0.1'
  s.dependency 'YYCache', '~> 1.0.4'
  
end

#
# Be sure to run `pod lib lint IBToCode.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IBToCode'
  s.version          = '0.1.1'
  s.summary          = 'Generate the code to recreate a layout made in Interface Builder programmatically.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This library helps you build views programmatically by turning a layout made in Interface Builder into the code needed to build the equivalent layout in code (Swift 3 for the moment). It recreate the view hierarchy, constraints (in SnapKit or Anchors syntax on option) and extract a few basic properties, like backgroundColor and titles.
                       DESC

  s.homepage         = 'https://github.com/xdaleau/IBToCode'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
  s.author           = { 'Xavier Daleau' => 'xavier.daleau@gmail.com' }
  s.source           = { :git => 'https://github.com/xdaleau/IBToCode.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'IBToCode/Classes/**/*'
  
  # s.resource_bundles = {
  #   'IBToCode' => ['IBToCode/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

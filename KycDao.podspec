#
# Be sure to run `pod lib lint KycDao.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KycDao'
  s.version          = '0.1.0'
  s.summary          = 'A short description of KycDao.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/kycdao/kycdao-ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Cydie' => 'robin.vekety@gmail.com' }
  s.source           = { :git => 'https://github.com/kycdao/kycdao-ios-sdk', :branch => 'main' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/**/*'
  
  # s.resource_bundles = {
  #   'KycDao' => ['KycDao/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'web3.swift', '~> 1.4.0'
  s.dependency 'WalletConnectSwift', '~> 1.7.0'
  s.dependency 'PersonaInquirySDK2', '~> 2.3.0'
  s.dependency 'CombineExt', '~> 1.8.0'
  s.swift_versions = '5.0'
end

#
# Be sure to run `pod lib lint PhotoSubmitter.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PhotoSubmitter"
  s.version          = "0.1.0"
  s.summary          = "A short description of PhotoSubmitter."
  s.description      = <<-DESC
                       An optional longer description of PhotoSubmitter

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/PhotoSubmitter"
  s.license          = 'MIT'
  s.author           = { "kent013" => "kentaro.ishitoya@gmail.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/PhotoSubmitter.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/*.{h,m}', 'Pod/Classes/{Libraries,Entities,UtilityCategories,Settings}/**/*.{h,m}'
  s.resource_bundles = {
    'PhotoSubmitter' => ['Pod/Assets/*.png']
  }
  s.dependency "FBNetworkReachability"
  s.dependency "KissXML"
  s.dependency "RestKit"
  s.dependency "SVProgressHUD"
  s.dependency "MAConfirmButton"
  s.dependency "UIImage-Categories"
  s.dependency "NYXImagesKit"
  s.dependency "ZipArchive"
  s.dependency "PDKeychainBindingsController"
  s.dependency "Reachability"
  s.dependency "SBJson"
  s.dependency "RegexKitLite"
  s.dependency "Base64nl"
end

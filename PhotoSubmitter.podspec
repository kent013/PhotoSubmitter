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
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Pod/Classes/*.{h,m}', 'Pod/Classes/{Libraries,Entities,UtilityCategories,Settings}/**/*.{h,m}'
    core.resource_bundle = {
      'ENGPhotoSubmitter' => 
        ['Pod/Assets/Images/*.png',
         'Pod/Assets/Localizations/*.lproj']
    }
    core.dependency "FBNetworkReachability"
    core.dependency "KissXML"
    core.dependency "RestKit"
    core.dependency "SVProgressHUD"
    core.dependency "MAConfirmButton"
    core.dependency "UIImage-Categories"
    core.dependency "NYXImagesKit"
    core.dependency "ZipArchive"
    core.dependency "PDKeychainBindingsController"
    core.dependency "Reachability"
    core.dependency "RegexKitLite"
    core.dependency "Base64nl"
  end
  
  s.subspec 'Dropbox' do |dropbox|
    dropbox.source_files = 'Pod/Classes/Services/DropboxPhotoSubmitter/**/*.{h,m}'
    dropbox.dependency 'Dropbox-iOS-SDK'
    dropbox.resource_bundle = {
      'ENGPhotoSubmitter-Dropbox' => 'Pod/Classes/Services/DropboxPhotoSubmitter/Resources/Images/*.png'
    }
  end

  s.subspec 'Facebook' do |facebook|
    facebook.source_files = 'Pod/Classes/Services/FacebookPhotoSubmitter/**/*.{h,m}'
    facebook.dependency 'Facebook-iOS-SDK'
    facebook.resource_bundle = {
      'ENGPhotoSubmitter-Facebook' => 'Pod/Classes/Services/FacebookPhotoSubmitter/Resources/Images/*.png'
    }
  end

#s.subspec 'GoogleDrive' do |gdrive|
#  gdrive.source_files = 'Pod/Classes/Services/GoogleDrivePhotoSubmitter/**/*.{h,m}'
#  gdrive.dependency 'Google-API-Client'
#  gdrive.dependency 'Google-API-Client/Drive'
#  gdrive.resource_bundle = {
#    'ENGPhotoSubmitter-GoogleDrive' => 'Pod/Classes/Services/GoogleDrivePhotoSubmitter/Resources/Images/*.png'
#  }
#end

  s.subspec 'File' do |file|
    file.source_files = 'Pod/Classes/Services/FilePhotoSubmitter/**/*.{h,m}'
    file.resource_bundle = {
      'ENGPhotoSubmitter-File' => 'Pod/Classes/Services/FilePhotoSubmitter/Resources/Images/*.png'
    }
  end

  s.subspec 'Twitter' do |twitter|
    twitter.source_files = 'Pod/Classes/Services/TwitterPhotoSubmitter/**/*.{h,m}'
    twitter.resource_bundle = {
      'ENGPhotoSubmitter-Twitter' => 'Pod/Classes/Services/TwitterPhotoSubmitter/Resources/Images/*.png'
    }
  end

  s.subspec 'MetaMovics' do |metamovics|
    metamovics.source_files = 'Pod/Classes/Services/MetaMovicsPhotoSubmitter/**/*.{h,m}'
    metamovics.resource_bundle = {
      'ENGPhotoSubmitter-MetaMovics' => 'Pod/Classes/Services/MetaMovicsPhotoSubmitter/Resources/Images/*.png'
  }
  end
end

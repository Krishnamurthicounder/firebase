# This podspec is not intended to be deployed. It is solely for the static
# library framework build process at
# https://github.com/firebase/firebase-ios-sdk/tree/master/BuildFrameworks

Pod::Spec.new do |s|
  s.name             = 'FirebaseCore'
  s.version          = '4.1.0'
  s.summary          = 'Firebase Open Source Libraries for iOS.'

  s.description      = <<-DESC
Simplify your iOS development, grow your user base, and monetize more effectively with Firebase.
                       DESC

  s.homepage         = 'https://firebase.google.com'
  s.license          = { :type => 'Apache', :file => '../../LICENSE' }
  s.authors          = 'Google, Inc.'

  # NOTE that the FirebaseDev pod is neither publicly deployed nor yet interchangeable with the
  # Firebase pod
  s.source           = { :git => 'https://github.com/firebase/firebase-ios-sdk.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Firebase'
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.10'

  eitherSource = lambda { |paths|
    Array(paths).map { |path| ['Firebase/Core/Source/' + path, 'Source/' + path] }.flatten
  }

  s.source_files = eitherSource[[
    'FirebaseCore.h',
    'FIRAnalyticsConfiguration.h',
    'FIRApp.h',
    'FIRConfiguration.h',
    'FIRLoggerLevel.h',
    'FIROptions.h',
    'FIRCoreSwiftNameSupport.h'
  ]]
  
  # Necessary hack to appease header visibility while as a direct OR transitive/internal dependency
  s.subspec 'Internal' do |ss|
    ss.source_files = eitherSource['**/*.[mh]']
    ss.private_header_files = eitherSource['**/*.h']
  end

  s.dependency 'GoogleToolboxForMac/NSData+zlib', '~> 2.1'
end

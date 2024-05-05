# Uncomment the next line to define a global platform for your project
platform :ios, '17.2'

target 'A4' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for A4
  pod 'GoogleSignIn'
  
  pod 'Firebase'
  pod 'Firebase/Auth'
  pod 'AppAuth', '~> 1.7'
  pod 'Firebase/Firestore'
  pod 'FirebaseFirestoreSwift'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'


  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'

  pod 'Charts'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
    end
  end
end


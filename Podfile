# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

# include public/private pods
source 'git@github.com:cocoapods/Specs.git'


workspace './Pidgin.xcworkspace'
swift_version = '5.0'
use_frameworks!

target 'Pidgin' do
  pod 'NextLevel', '0.16.0'
  pod 'SvrfSDK'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        # setup NextLevel for ARKit use
        if target.name == 'NextLevel'
          target.build_configurations.each do |config|
            config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -DUSE_ARKIT'
          end
        end
    end
end
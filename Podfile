  
# include public/private pods
source 'git@github.com:cocoapods/Specs.git'



workspace './Pidgin.xcworkspace'

use_frameworks!


target 'Pidgin' do
  pod 'SvrfSDK'
  pod 'NextLevel'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Messaging'
  pod 'Firebase/Storage'
  pod 'Google-Mobile-Ads-SDK'
  pod 'MessageKit'
  pod 'Eureka'
  pod 'NotificationBannerSwift'
  pod 'ViewRow'
  pod 'Kingfisher'
  pod 'Lightbox'
  pod 'Giphy'
  pod 'CropViewController'
  pod 'Hero'
  pod 'DZNEmptyDataSet'
  pod 'CollectionViewWaterfallLayout'
  pod 'SkeletonView'
  pod 'Firebase/Database'
  pod "SwipeTransition"
  pod "SwipeTransitionAutoSwipeBack"      # if needed
  pod 'CarbonKit'
  pod 'SPPermissions/Notification'
  pod 'SPPermissions/Camera'
  pod 'SPPermissions/Microphone'
  pod 'SPPermissions/PhotoLibrary'
  pod 'AwesomeSpotlightView'
  pod 'SnapSDK', :subspecs => ['SCSDKCreativeKit']


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




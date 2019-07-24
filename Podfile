inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'

target :'Lockdown' do
    pod 'ReachabilitySwift'
    pod 'SwiftMessages', '6.0.0'
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'CNPPopupController'
    pod 'LGSideMenuController', '2.1.1'
    pod 'Alamofire'
    pod 'SkyFloatingLabelTextField', '~> 3.0'
    pod 'TextFieldEffects'
    pod 'KeychainAccess'
    pod 'Segmentio'
    pod 'NVActivityIndicatorView'
    pod 'CocoaLumberjack'
    pod 'PopupDialog', '~> 0.9'
    pod 'SDWebImage'
end


target :'LockdownTunnel' do
  pod 'KeychainAccess'
  pod 'ReachabilitySwift'
end

target :'Today' do
    pod 'PromiseKit'
    pod 'PromiseKit/Alamofire', '~> 6.0'
    pod 'SwiftyStoreKit', '0.13.1'
    pod 'Alamofire'
    pod 'KeychainAccess'
    pod 'CocoaLumberjack'
    pod 'ReachabilitySwift'
end

post_install do |installer| 
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end

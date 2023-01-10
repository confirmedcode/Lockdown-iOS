inhibit_all_warnings!
use_frameworks!

platform :ios, '13.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end

target :'Lockdown' do
  plugin 'cocoapods-acknowledgements', :settings_bundle => true
  pod 'AwesomeSpotlightView'
  pod 'RQShineLabel'
  pod 'NicoProgress'
  pod 'ReachabilitySwift', '4.3.1'
  pod 'SwiftMessages', '6.0.0'
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'PopupDialog', '~> 0.9'
  
  #Linter
  pod 'SwiftLint'
end

target :'LockdownTunnel' do
  pod 'PromiseKit'
  pod 'KeychainAccess'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'ReachabilitySwift', '4.3.1'
end

target :'Lockdown VPN Widget' do
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'ReachabilitySwift', '4.3.1'
end

target :'Lockdown Firewall Widget' do
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'ReachabilitySwift', '4.3.1'
end

target :'LockdownIntents' do
   pod 'PromiseKit'
   pod 'SwiftyStoreKit', '0.13.1'
   pod 'KeychainAccess'
   pod 'CocoaLumberjack'
   pod 'ReachabilitySwift', '4.3.1'
 end

target :'LockdownTests' do
  # see https://github.com/pointfreeco/swift-snapshot-testing/pull/308
  pod 'SnapshotTesting', :git => 'https://github.com/pointfreeco/swift-snapshot-testing.git', :commit => '8e9f685'
end

# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     target.build_configurations.each do |config|
#       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
#     end
#   end
# end

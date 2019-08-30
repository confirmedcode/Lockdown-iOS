inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'

target :'Lockdown' do
  plugin 'cocoapods-acknowledgements', :settings_bundle => true
  pod 'AwesomeSpotlightView'
  pod 'RQShineLabel'
  pod 'NicoProgress'
  pod 'ReachabilitySwift'
  pod 'SwiftMessages', '6.0.0'
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'PopupDialog', '~> 0.9'
end

target :'LockdownTunnel' do
  pod 'PromiseKit'
  pod 'KeychainAccess'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'ReachabilitySwift'
  pod 'CocoaLumberjack'
end

target :'Lockdown VPN Widget' do
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'ReachabilitySwift'
end

target :'Lockdown Firewall Widget' do
  pod 'PromiseKit'
  pod 'SwiftyStoreKit', '0.13.1'
  pod 'KeychainAccess'
  pod 'CocoaLumberjack'
  pod 'ReachabilitySwift'
end

# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     target.build_configurations.each do |config|
#       config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
#     end
#   end
# end

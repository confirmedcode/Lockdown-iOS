# Lockdown Privacy (iOS)

Lockdown is an open source firewall that blocks trackers, ads, and badware in all apps. Product details at [lockdownhq.com](https://lockdownhq.com).

### Feature Requests + Bugs

Create an issue on Github for feature requests and bug reports.

### Contributing

Pull requests are welcome - please document any changes and potential bugs.

### Build Instructions

1. `pod install`

2. `carthage update --no-use-binaries --platform ios` or for XCode 12 `./wcarthage update --no-use-binaries --platform ios` (workaround for [this Carthage issue](https://github.com/Carthage/Carthage/issues/3019)) 

3. Open `LockdowniOS.xcworkspace`

To sign the app for devices, you will need an Apple Developer account.

### Contact

[team@lockdownhq.com](mailto:team@lockdownhq.com)

### License

This project is licensed under the GPL License - see the [LICENSE.md](LICENSE.md) file for details.




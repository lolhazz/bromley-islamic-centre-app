# Bromley Islamic Centre app

An iPhone app for Bromley Islamic Centre, written in SwiftUI (iOS 18).

- Daily prayer times, next-prayer countdown and Qibla compass
- Reminder alerts using local notifications, with extra alerts in Ramadan
- Events and centre information
- Home-screen and lock-screen widgets
- Committee editor (in `admin/`) so service times, events and announcements can be changed without an app update

## Build

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
xcodegen generate
open BromleyIslamicCentre.xcodeproj
```

Unit tests are in `Tests/`. The editor's API checks run with `npm test` inside `admin/`.

# Bromley Islamic Centre app

An iPhone app for Bromley Islamic Centre, written in SwiftUI for iOS 18.

It shows daily prayer times with a countdown to the next prayer, a Qibla compass, events and centre information. It sends reminder alerts as local notifications, with extra alerts during Ramadan, and has home-screen and lock-screen widgets. The committee can change service times, events and announcements from a phone using the editor in `admin/`, so an app update isn't needed.

## Build

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
xcodegen generate
open BromleyIslamicCentre.xcodeproj
```

App tests are in `Tests/`. The editor's API checks run with `npm test` inside `admin/`.

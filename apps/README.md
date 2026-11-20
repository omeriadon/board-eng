# apps — SwiftUI clients (iOS 26 + macOS 26)

```sh
cd apps
xcodegen generate     # regenerate Board.xcodeproj from project.yml after adding files
open Board.xcodeproj
```

- `Board/Shared`: code shared by both platforms (sections, store, live preview, Dither settings, quick controls)
- `Board/iOS`: `TabView(.sidebarAdaptable)`; more than 5 tabs → More; quick controls in `tabViewBottomAccessory`
- `Board/macOS`: `NavigationSplitView` sidebar + toolbar quick controls + `MenuBarExtra`
- Depends on `../shared/BoardKit` (local package)

Set your Development Team in Xcode (or in `project.yml`) to run on a device. See [`../docs/app-plan.md`](../docs/app-plan.md).

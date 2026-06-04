# Commute Buddy — macOS

A menu bar app built with SwiftUI. Click the tram icon in the menu bar to see upcoming PATH trains and whether to leave.

Requires macOS 13 (Ventura) or later.

## Project structure

```
mac/CommuteBuddy/
├── CommuteBuddyApp.swift        # App entry point — MenuBarExtra
├── CommuteViewModel.swift       # State management, direction detection, refresh loop
├── Config.swift                 # Commute settings (edit this)
├── Models/
│   ├── Direction.swift          # .toWork / .toHome
│   └── Train.swift              # Train model + NSColor hex helper
├── Services/
│   └── PathService.swift        # PANYNJ API fetch (no proxy needed — URLSession sets Referer)
└── Views/
    └── ContentView.swift        # Menu bar panel UI
```

## Setting up the Xcode project

The Swift source files are ready — you just need to wrap them in an Xcode project:

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**
3. Set the following:
   - **Product Name**: CommuteBuddy
   - **Bundle Identifier**: `com.yourname.commutebuddy`
   - **Interface**: SwiftUI
   - **Language**: Swift
4. Save the project **inside `mac/`** (next to the `CommuteBuddy/` folder)
5. In the project navigator, **delete** the placeholder `ContentView.swift` Xcode created
6. **Add the existing files**: right-click the group → *Add Files to "CommuteBuddy"* → select all files inside `mac/CommuteBuddy/`
7. In **Signing & Capabilities**, set your Team
8. Set **Deployment Target** to macOS 13.0

### Info.plist — hide from Dock

Add this key so the app lives only in the menu bar (no Dock icon, no App Switcher entry):

| Key | Type | Value |
|---|---|---|
| `Application is agent (UIElement)` | Boolean | YES |

Or in raw XML: `<key>LSUIElement</key><true/>`

### Network entitlement

In **Signing & Capabilities → + Capability → App Sandbox**, enable:
- **Outgoing Connections (Client)** ✓

This allows URLSession to reach the PANYNJ API.

## Running

Press **⌘R** in Xcode. A tram icon appears in your menu bar — click it to open the panel.

## Data source

Calls `https://www.panynj.gov/bin/portauthority/ridepath.json` directly via `URLSession`.
Sets `Referer: https://www.panynj.gov/path/en/index.html` in the request headers — 
URLSession can set this freely (unlike a browser, there is no CORS restriction).

No Cloudflare Worker proxy needed for native apps.

## Roadmap

- [ ] Dynamic menu bar icon (changes on Go/Wait state)
- [ ] `UNUserNotificationCenter` push — "leave in 5 min" notification
- [ ] Auto / On mode toggle (mirroring the web app)
- [ ] LaunchAtLogin support

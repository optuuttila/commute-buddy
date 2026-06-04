import SwiftUI

@main
struct CommuteBuddyApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            // Tram icon — swaps to filled variant when a commute window is active.
            // TODO: update icon dynamically based on Go/Wait state.
            Image(systemName: "tram.fill")
        }
        .menuBarExtraStyle(.window)  // renders ContentView in a floating panel
    }
}

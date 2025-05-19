import SwiftUI
import SwiftData
import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return false // No dejar que el sistema haga nada más
        }
        return true
    }
}

@main
struct cutepomoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false
    @StateObject private var updaterController = UpdaterController()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .modelContainer(for: Item.self, inMemory: true)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 70)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.checkForUpdates()
                }
                .disabled(!updaterController.canCheckForUpdates)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// Update window level for always on top behavior
private func updateMainWindowLevel(alwaysOnTop: Bool) {
    DispatchQueue.main.async {
        for window in NSApp.windows {
            if window.isMainWindow || window.isKeyWindow {
                window.level = alwaysOnTop ? .floating : .normal
            }
        }
    }
}


import SwiftUI
import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController: SPUStandardUpdaterController
    
    override init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Inicializar Sparkle
        updaterController.startUpdater()
    }
    
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
    
    private var updaterController: SPUStandardUpdaterController {
        return appDelegate.updaterController
    }
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 140, height: 70)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .commands {
            // App Info Commands
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
            }
            
            // Timer Commands
            CommandGroup(replacing: .newItem) {
                Button("Start/Pause") {
                    NotificationCenter.default.post(name: Notification.Name("ToggleTimer"), object: nil)
                }
                .keyboardShortcut(.space, modifiers: .command)
                
                Button("Reset") {
                    NotificationCenter.default.post(name: Notification.Name("ResetTimer"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Switch Mode") {
                    NotificationCenter.default.post(name: Notification.Name("SwitchTimerMode"), object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            // View Commands
            CommandGroup(after: .toolbar) {
                Button(alwaysOnTop ? "Float Window: ON" : "Float Window: OFF") {
                    alwaysOnTop.toggle()
                    updateMainWindowLevel(alwaysOnTop: alwaysOnTop)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            
            // Help Commands
            CommandGroup(replacing: .help) {
                Button("About cutepomo") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
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




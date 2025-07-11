import SwiftUI
import AppKit

fileprivate func updateMainWindowLevel(alwaysOnTop: Bool) {
    DispatchQueue.main.async {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
            window.level = alwaysOnTop ? .floating : .normal
        }
    }
}

fileprivate func updateMainWindowSize(compactMode: Bool) {
    DispatchQueue.main.async {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
            let size = compactMode ? NSSize(width: 140, height: 70) : NSSize(width: 140, height: 70)
            window.setContentSize(size)
            window.minSize = size
            window.maxSize = size
            window.setFrame(NSRect(origin: window.frame.origin, size: size), display: true, animate: true)
            window.center()
        }
    }
}

fileprivate func assignMainWindowIdentifier() {
    DispatchQueue.main.async {
        for window in NSApp.windows {
            if window.title.isEmpty || window.title == "cutepomo" {
                window.identifier = NSUserInterfaceItemIdentifier("MainAppWindow")
            }
        }
    }
}

struct MainContentView: View {
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false
    
    var body: some View {
        ContentView()
            .onAppear {
                assignMainWindowIdentifier()
                // Espera breve para asegurar que el identificador esté asignado
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    configureWindow()
                    updateWindowLevel(alwaysOnTop: self.alwaysOnTop)
                }
            }
            .onChange(of: alwaysOnTop) { _, newValue in
                updateWindowLevel(alwaysOnTop: newValue)
            }
    }
    
    private func configureWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
                // Quitar .titled y poner .borderless para eliminar la title bar y su espacio
                window.styleMask = [.borderless, .fullSizeContentView]
                window.isMovableByWindowBackground = true
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.level = alwaysOnTop ? .floating : .normal
                
                // Redondear la ventana físicamente
                if let contentView = window.contentView?.superview {
                    contentView.wantsLayer = true
                    contentView.layer?.cornerRadius = 14
                    contentView.layer?.maskedCorners = [
                        .layerMinXMinYCorner, .layerMaxXMinYCorner,
                        .layerMinXMaxYCorner, .layerMaxXMaxYCorner
                    ]
                    contentView.layer?.masksToBounds = true
                }
            }
        }
    }
    
    private func updateWindowLevel(alwaysOnTop: Bool) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
                window.level = alwaysOnTop ? .floating : .normal
            }
        }
    } // Ya estaba correcto, solo asegúrate de llamarlo cuando cambie alwaysOnTop
    
    private func updateWindowSize(compactMode: Bool) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
                let size = compactMode ? NSSize(width: 140, height: 70) : NSSize(width: 140, height: 70)
                window.setContentSize(size)
                window.minSize = size
                window.maxSize = size
                window.setFrame(NSRect(origin: window.frame.origin, size: size), display: true, animate: false)
            }
        }
    }
}

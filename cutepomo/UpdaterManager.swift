import Foundation
import AppKit
import Sparkle

@MainActor
class UpdaterManager: ObservableObject {
    static let shared = UpdaterManager()
    
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    @Published var isCheckingForUpdates = false
    
    private init() {
        // Inicializar el controlador de actualizaciones
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Configurar el estado inicial
        self.canCheckForUpdates = updaterController.updater.canCheckForUpdates
        
        // Observar cambios en el estado del updater
        setupObservers()
    }
    
    private func setupObservers() {
        // Observar si podemos verificar actualizaciones
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }
    
    // MARK: - Funciones públicas
    
    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        
        isCheckingForUpdates = true
        updaterController.checkForUpdates(nil)
        
        // Reset el estado después de un delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isCheckingForUpdates = false
        }
    }
    
    func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    var automaticallyChecksForUpdates: Bool {
        get {
            updaterController.updater.automaticallyChecksForUpdates
        }
        set {
            updaterController.updater.automaticallyChecksForUpdates = newValue
        }
    }
    
    var automaticallyDownloadsUpdates: Bool {
        get {
            updaterController.updater.automaticallyDownloadsUpdates
        }
        set {
            updaterController.updater.automaticallyDownloadsUpdates = newValue
        }
    }
    
    var updateCheckInterval: TimeInterval {
        get {
            updaterController.updater.updateCheckInterval
        }
        set {
            updaterController.updater.updateCheckInterval = newValue
        }
    }
}

// MARK: - Menu Items Support
extension UpdaterManager {
    func createCheckForUpdatesMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdatesMenuAction),
            keyEquivalent: ""
        )
        menuItem.target = self
        return menuItem
    }
    
    @objc private func checkForUpdatesMenuAction() {
        checkForUpdates()
    }
} 
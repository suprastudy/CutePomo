import Foundation
import Sparkle

final class UpdaterController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Automatically check for updates
        updaterController.updater.automaticallyChecksForUpdates = true
        updaterController.updater.updateCheckInterval = 3600 * 24 // Check once per day
        
        // Enable or disable the automatic update checking
        canCheckForUpdates = true
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
} 
//
//  Migrator.swift
//  Loop
//
//  Created by Kai Azim on 2024-03-22.
//

import Defaults
import SwiftUI

// MARK: - Saved Keybinds Format

/// Struct to represent the JSON contents of a Loop keybinds file.
struct SavedKeybindsFormat: Codable {
    let version: String?
    let triggerKey: Set<CGKeyCode>?
    let actions: [SavedWindowActionFormat]

    static func generateFromDefaults() -> SavedKeybindsFormat {
        SavedKeybindsFormat(
            version: Bundle.main.appVersion,
            triggerKey: Defaults[.triggerKey],
            actions: Defaults[.keybinds].map { SavedWindowActionFormat($0) }
        )
    }
}

// MARK: - SavedWindowActionFormat

/// Struct to define the format of saved window actions.
struct SavedWindowActionFormat: Codable {
    let direction: WindowDirection
    let keybind: Set<CGKeyCode>
    let name: String?
    let unit: CustomWindowActionUnit?
    let anchor: CustomWindowActionAnchor?
    let sizeMode: CustomWindowActionSizeMode?
    let width: Double?
    let height: Double?
    let positionMode: CustomWindowActionPositionMode?
    let xPoint: Double?
    let yPoint: Double?
    let cycle: [SavedWindowActionFormat]?

    /// Initialize from a WindowAction.
    init(_ action: WindowAction) {
        self.direction = action.direction
        self.keybind = action.keybind
        self.name = action.name
        self.unit = action.unit
        self.anchor = action.anchor
        self.sizeMode = action.sizeMode
        self.width = action.width
        self.height = action.height
        self.positionMode = action.positionMode
        self.xPoint = action.xPoint
        self.yPoint = action.yPoint
        self.cycle = action.cycle?.map { SavedWindowActionFormat($0) }
    }

    /// Converts the saved format back into a usable WindowAction object.
    func convertToWindowAction() -> WindowAction {
        WindowAction(
            direction,
            keybind: keybind,
            name: name,
            unit: unit,
            anchor: anchor,
            width: width,
            height: height,
            xPoint: xPoint,
            yPoint: yPoint,
            positionMode: positionMode,
            sizeMode: sizeMode,
            cycle: cycle?.map { $0.convertToWindowAction()
            }
        )
    }
}

// MARK: - Migrator

enum MigratorError: Error {
    case keybindsEmpty
    case failedToConvertToString
    case mainWindowNotAvailableForPanel
    case fileSelectionCancelled
    case directorySelectionCancelled
    case failedToReadFile

    var localizedDescription: String {
        switch self {
        case .keybindsEmpty:
            "Keybinds are empty."
        case .failedToConvertToString:
            "Failed to convert keybinds to string."
        case .mainWindowNotAvailableForPanel:
            "Main window not available for panel."
        case .fileSelectionCancelled:
            "File selection was cancelled."
        case .directorySelectionCancelled:
            "Directory selection was cancelled."
        case .failedToReadFile:
            "Failed to read file."
        }
    }
}

// Adds functionality for saving, loading, and managing window actions.
enum Migrator {
    /// Presents a prompt to export current keybinds to a JSON file.
    static func exportPrompt() async throws {
        // Check if there are any keybinds to export.
        guard !Defaults[.keybinds].isEmpty else {
            await showAlert(
                .init(
                    localized: "Export empty keybinds alert title",
                    defaultValue: "No Keybinds Have Been Set"
                ),
                informativeText: .init(
                    localized: "Export empty keybinds alert description",
                    defaultValue: "You can't export something that doesn't exist!"
                )
            )

            throw MigratorError.keybindsEmpty
        }

        let directoryURL = try await getSaveDirectoryURL()
        let keybinds = SavedKeybindsFormat.generateFromDefaults()
        try await saveKeybinds(keybinds, in: directoryURL)

        Notification.Name.didExportKeybindsSuccessfully.post()
    }

    /// Presents a prompt to import keybinds from a JSON file.
    static func importPrompt() async throws {
        let fileURL = try await getKeybindsFileURL()
        let jsonString = try String(contentsOf: fileURL)

        do {
            try await importKeybinds(from: jsonString)
        } catch {
            if case MigratorError.failedToReadFile = error {
                await showAlert(
                    .init(
                        localized: "Error reading keybinds alert title",
                        defaultValue: "Error Reading Keybinds"
                    ),
                    informativeText: .init(
                        localized: "Error reading keybinds alert description",
                        defaultValue: "Make sure the file you selected is in the correct format."
                    )
                )
            } else {
                throw error
            }
        }
    }
}

// MARK: Migrator + Export

private extension Migrator {
    @MainActor
    static func getSaveDirectoryURL() async throws -> URL {
        let savePanel = NSSavePanel()
        savePanel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        savePanel.title = .init(localized: "Export keybinds")
        savePanel.nameFieldStringValue = "Loop Keybinds.json"

        guard let window = NSApplication.shared.mainWindow else {
            throw MigratorError.mainWindowNotAvailableForPanel
        }

        let result = await savePanel.beginSheetModal(for: window)

        guard result == .OK, let destUrl = savePanel.url else {
            throw MigratorError.directorySelectionCancelled
        }

        return destUrl
    }

    static func saveKeybinds(_: SavedKeybindsFormat, in directoryURL: URL) async throws {
        let keybinds = SavedKeybindsFormat.generateFromDefaults()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(keybinds)

        guard let json = String(data: data, encoding: .utf8) else {
            throw MigratorError.failedToConvertToString
        }

        try json.write(
            to: directoryURL,
            atomically: true,
            encoding: .utf8
        )
    }
}

// MARK: Migrator + Import

private extension Migrator {
    /// Presents a file picker to select a keybinds file.
    @MainActor
    static func getKeybindsFileURL() async throws -> URL {
        let openPanel = NSOpenPanel()
        openPanel.title = .init(localized: "Select a keybinds file")
        openPanel.allowedContentTypes = [.json]

        guard let window = NSApplication.shared.mainWindow else {
            throw MigratorError.mainWindowNotAvailableForPanel
        }

        let result = await openPanel.beginSheetModal(for: window)

        guard result == .OK, let selectedFileURL = openPanel.url else {
            throw MigratorError.fileSelectionCancelled
        }

        return selectedFileURL
    }

    /// Imports keybinds from a JSON string.
    static func importKeybinds(from jsonString: String) async throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw MigratorError.failedToReadFile
        }

        /// First, try to import the general Loop keybinds format.
        do {
            let savedData = try await importLoopKeybinds(from: data)
            await updateDefaults(with: savedData)
            return
        } catch {
            print("Error importing Loop keybinds: \(error)")
        }

        /// If that fails, try to import the old Loop (pre 1.2.0) keybinds format.
        do {
            let savedData = try await importLoopLegacyKeybinds(from: data)
            await updateDefaults(with: savedData)
            return
        } catch {
            print("Error importing Loop (pre 1.2.0) keybinds: \(error)")
        }

        /// If that fails, try to import the Rectangle keybinds format.
        do {
            let savedData = try await importRectangleKeybinds(from: data)
            await updateDefaults(with: savedData)
            return
        } catch {
            print("Error importing Rectangle keybinds: \(error)")
        }

        // If all attempts fail, show an error alert.
        throw MigratorError.failedToReadFile
    }

    /// Tries to import Loop's keybinds format.
    static func importLoopKeybinds(from data: Data) async throws -> SavedKeybindsFormat {
        let decoder = JSONDecoder()
        let keybinds = try decoder.decode(SavedKeybindsFormat.self, from: data)
        return keybinds
    }

    /// Tries to import Loop's old (pre 1.2.0) keybinds format.
    static func importLoopLegacyKeybinds(from data: Data) async throws -> SavedKeybindsFormat {
        let decoder = JSONDecoder()
        let keybinds = try decoder.decode([SavedWindowActionFormat].self, from: data)
        return SavedKeybindsFormat(version: nil, triggerKey: nil, actions: keybinds)
    }

    /// Tries to import Rectangle's keybinds format.
    static func importRectangleKeybinds(from data: Data) async throws -> SavedKeybindsFormat {
        let keybinds = try RectangleTranslationLayer.importKeybinds(from: data)
        return SavedKeybindsFormat(version: nil, triggerKey: nil, actions: keybinds)
    }

    // MARK: Saving Imports

    /// Updates the app's defaults with the imported keybinds.
    static func updateDefaults(with savedData: SavedKeybindsFormat) async {
        if let triggerKey = savedData.triggerKey {
            Defaults[.triggerKey] = triggerKey
        }

        if Defaults[.keybinds].isEmpty {
            Defaults[.keybinds] = savedData.actions.map { $0.convertToWindowAction() }

            // Post a notification after updating the keybinds
            Notification.Name.didImportKeybindsSuccessfully.post()
        } else {
            let result = await showAlertForImportDecision()

            switch result {
            case .merge:
                let newKeybinds = savedData.actions
                    .map { $0.convertToWindowAction() }
                    .filter { newKeybind in
                        !Defaults[.keybinds].contains { $0.keybind == newKeybind.keybind && $0.name == newKeybind.name }
                    }

                Defaults[.keybinds].append(contentsOf: newKeybinds)

                // Post a notification after updating the keybinds
                Notification.Name.didImportKeybindsSuccessfully.post()
            case .erase:
                Defaults[.keybinds] = savedData.actions.map { $0.convertToWindowAction() }

                // Post a notification after updating the keybinds
                Notification.Name.didImportKeybindsSuccessfully.post()
            case .cancel:
                // No action needed, no notification should be posted
                break
            }
        }
    }

    /// Presents a decision alert for how to handle imported keybinds.
    static func showAlertForImportDecision() async -> ImportDecision {
        let response = await showAlert(
            .init(localized: "Import Keybinds"),
            informativeText: .init(localized: "Do you want to merge or erase existing keybinds?"),
            buttons: [
                .init(localized: "Import keybinds: merge", defaultValue: "Merge"),
                .init(localized: "Import keybinds: erase", defaultValue: "Erase"),
                .init(localized: "Import keybinds: cancel", defaultValue: "Cancel")
            ]
        )

        switch response {
        case .alertFirstButtonReturn:
            return .merge
        case .alertSecondButtonReturn:
            return .erase
        default:
            return .cancel
        }
    }

    /// Utility function to show an alert with a completion handler.
    @MainActor
    @discardableResult
    static func showAlert(
        _ messageText: String,
        informativeText: String,
        buttons: [String] = []
    ) async -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        buttons.forEach { alert.addButton(withTitle: $0) }

        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            return await alert.beginSheetModal(for: window)
        } else {
            return alert.runModal()
        }
    }

    /// Enum to represent the decision made in the import decision alert.
    enum ImportDecision {
        case merge, erase, cancel
    }
}

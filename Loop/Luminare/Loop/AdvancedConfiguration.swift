//
//  AdvancedConfiguration.swift
//  Loop
//
//  Created by Kai Azim on 2024-04-26.
//

import Combine
import Defaults
import Luminare
import SwiftUI

class AdvancedConfigurationModel: ObservableObject {
    @Published var useSystemWindowManagerWhenAvailable = Defaults[.useSystemWindowManagerWhenAvailable] {
        didSet {
            Defaults[.useSystemWindowManagerWhenAvailable] = useSystemWindowManagerWhenAvailable
            Notification.Name.systemWindowManagerStateChanged.post()
        }
    }

    @Published var animateWindowResizes = Defaults[.animateWindowResizes] {
        didSet { Defaults[.animateWindowResizes] = animateWindowResizes }
    }

    @Published var hideUntilDirectionIsChosen = Defaults[.hideUntilDirectionIsChosen] {
        didSet { Defaults[.hideUntilDirectionIsChosen] = hideUntilDirectionIsChosen }
    }

    @Published var disableCursorInteraction = Defaults[.disableCursorInteraction] {
        didSet { Defaults[.disableCursorInteraction] = disableCursorInteraction }
    }

    @Published var ignoreFullscreen = Defaults[.ignoreFullscreen] {
        didSet { Defaults[.ignoreFullscreen] = ignoreFullscreen }
    }

    @Published var hapticFeedback = Defaults[.hapticFeedback] {
        didSet { Defaults[.hapticFeedback] = hapticFeedback }
    }

    @Published var sizeIncrement = Defaults[.sizeIncrement] {
        didSet { Defaults[.sizeIncrement] = sizeIncrement }
    }

    @Published var didImportSuccessfullyAlert = false
    @Published var didExportSuccessfullyAlert = false
    @Published var didResetSuccessfullyAlert = false

    @Published var isAccessibilityAccessGranted = AccessibilityManager.getStatus()
    @Published var isScreenCaptureAccessGranted = ScreenCaptureManager.getStatus()
    @Published var accessibilityChecker: Publishers.Autoconnect<Timer.TimerPublisher> = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Published var accessibilityChecks: Int = 0

    func importedSuccessfully() {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didImportSuccessfullyAlert = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didImportSuccessfullyAlert = false
            }
        }
    }

    func exportedSuccessfully() {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didExportSuccessfullyAlert = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didExportSuccessfullyAlert = false
            }
        }
    }

    func resetSuccessfully() {
        DispatchQueue.main.async { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didResetSuccessfullyAlert = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.smooth(duration: 0.5)) {
                self?.didResetSuccessfullyAlert = false
            }
        }
    }

    func beginAccessibilityAccessRequest() {
        accessibilityChecker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        accessibilityChecks = 0
        AccessibilityManager.requestAccess()
    }

    // No point in checking for screen capture permits since that REQUIRES a relaunch, unfortunately
    func refreshAccessiblityStatus() {
        accessibilityChecks += 1
        let isAccessibilityGranted = AccessibilityManager.getStatus()

        if isAccessibilityAccessGranted != isAccessibilityGranted {
            withAnimation(LuminareConstants.animation) {
                isAccessibilityAccessGranted = isAccessibilityGranted
            }
        }

        if isAccessibilityGranted || accessibilityChecks > 60 {
            accessibilityChecker.upstream.connect().cancel()
        }
    }
}

struct AdvancedConfigurationView: View {
    @Environment(\.tintColor) var tintColor
    @StateObject private var model = AdvancedConfigurationModel()
    let elementHeight: CGFloat = 34

    var body: some View {
        generalSection()
        keybindsSection()
        permissionsSection()
    }

    func generalSection() -> some View {
        LuminareSection("General") {
            if #available(macOS 15.0, *) {
                LuminareToggle("Use macOS window manager when available", isOn: $model.useSystemWindowManagerWhenAvailable)
            }
            LuminareToggle(
                "Animate window resize",
                info: .init("This feature is still under development.", .orange),
                isOn: $model.animateWindowResizes
            )
            LuminareToggle("Disable cursor interaction", isOn: $model.disableCursorInteraction)
            LuminareToggle("Ignore fullscreen windows", isOn: $model.ignoreFullscreen)
            LuminareToggle("Hide until direction is chosen", isOn: $model.hideUntilDirectionIsChosen)
            LuminareToggle("Haptic feedback", isOn: $model.hapticFeedback)

            LuminareValueAdjuster(
                "Size increment", // Description: Used in size adjustment window actions
                value: $model.sizeIncrement,
                sliderRange: 5...50,
                suffix: "px",
                step: 4.5,
                lowerClamp: true
            )
        }
    }

    func keybindsSection() -> some View {
        LuminareSection("Keybinds") {
            HStack(spacing: 2) {
                Button {
                    Task {
                        do {
                            try await Migrator.importPrompt()
                        } catch {
                            print("Error importing keybinds: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        Text("Import")

                        if model.didImportSuccessfullyAlert {
                            Image(systemName: "checkmark")
                                .foregroundStyle(tintColor())
                                .bold()
                        }
                    }
                }
                .onReceive(.didImportKeybindsSuccessfully) { _ in
                    model.importedSuccessfully()
                }

                Button {
                    Task {
                        do {
                            try await Migrator.exportPrompt()
                        } catch {
                            print("Error exporting keybinds: \(error)")
                        }
                    }
                } label: {
                    HStack {
                        Text("Export")

                        if model.didExportSuccessfullyAlert {
                            Image(systemName: "checkmark")
                                .foregroundStyle(tintColor())
                                .bold()
                        }
                    }
                }
                .onReceive(.didExportKeybindsSuccessfully) { _ in
                    model.exportedSuccessfully()
                }

                Button {
                    Defaults.reset(.keybinds)
                    model.resetSuccessfully()
                } label: {
                    HStack {
                        Text("Reset")

                        if model.didResetSuccessfullyAlert {
                            Image(systemName: "checkmark")
                                .foregroundStyle(tintColor())
                                .bold()
                        }
                    }
                }
                .buttonStyle(LuminareDestructiveButtonStyle())
            }
        }
    }

    func permissionsSection() -> some View {
        LuminareSection("Permissions") {
            accessibilityComponent()
            screenCaptureComponent()
        }
        .onReceive(model.accessibilityChecker) { _ in
            model.refreshAccessiblityStatus()
        }
    }

    func accessibilityComponent() -> some View {
        HStack {
            if model.isAccessibilityAccessGranted {
                Image(._18PxBadgeCheck2)
                    .foregroundStyle(tintColor())
            }

            Text("Accessibility access")

            Spacer()

            Button {
                model.beginAccessibilityAccessRequest()
            } label: {
                Text("Request…")
                    .frame(height: 30)
                    .padding(.horizontal, 8)
            }
            .disabled(model.isAccessibilityAccessGranted)
            .buttonStyle(LuminareCompactButtonStyle(extraCompact: true))
        }
        .padding(.leading, 8)
        .padding(.trailing, 2)
        .frame(height: elementHeight)
    }

    func screenCaptureComponent() -> some View {
        HStack {
            if model.isScreenCaptureAccessGranted {
                Image(._18PxBadgeCheck2)
                    .foregroundStyle(tintColor())
            }

            Text("Screen capture access")

            Spacer()

            Button {
                ScreenCaptureManager.requestAccess()
            } label: {
                Text("Request…")
                    .frame(height: 30)
                    .padding(.horizontal, 8)
            }
            .disabled(model.isScreenCaptureAccessGranted)
            .buttonStyle(LuminareCompactButtonStyle(extraCompact: true))
        }
        .padding(.leading, 8)
        .padding(.trailing, 2)
        .frame(height: elementHeight)
    }
}

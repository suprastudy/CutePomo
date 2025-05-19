//
//  BehaviorConfiguration.swift
//  Loop
//
//  Created by Kai Azim on 2024-04-19.
//

import Defaults
import Luminare
import ServiceManagement
import SwiftUI

class BehaviorConfigurationModel: ObservableObject {
    @Published var launchAtLogin = Defaults[.launchAtLogin] {
        didSet {
            Defaults[.launchAtLogin] = launchAtLogin

            do {
                if launchAtLogin {
                    try SMAppService().register()
                } else {
                    try SMAppService().unregister()
                }
            } catch {
                print("Failed to \(launchAtLogin ? "register" : "unregister") login item: \(error.localizedDescription)")
            }
        }
    }

    @Published var hideMenuBarIcon = Defaults[.hideMenuBarIcon] {
        didSet { Defaults[.hideMenuBarIcon] = hideMenuBarIcon }
    }

    @Published var animationConfiguration = Defaults[.animationConfiguration] {
        didSet { Defaults[.animationConfiguration] = animationConfiguration }
    }

    @Published var windowSnapping = Defaults[.windowSnapping] {
        didSet { Defaults[.windowSnapping] = windowSnapping }
    }

    @Published var restoreWindowFrameOnDrag = Defaults[.restoreWindowFrameOnDrag] {
        didSet { Defaults[.restoreWindowFrameOnDrag] = restoreWindowFrameOnDrag }
    }

    @Published var useSystemWindowManagerWhenAvailable = Defaults[.useSystemWindowManagerWhenAvailable] {
        didSet { Defaults[.useSystemWindowManagerWhenAvailable] = useSystemWindowManagerWhenAvailable }
    }

    @Published var enablePadding = Defaults[.enablePadding] {
        didSet { Defaults[.enablePadding] = enablePadding }
    }

    @Published var useScreenWithCursor = Defaults[.useScreenWithCursor] {
        didSet { Defaults[.useScreenWithCursor] = useScreenWithCursor }
    }

    @Published var moveCursorWithWindow = Defaults[.moveCursorWithWindow] {
        didSet { Defaults[.moveCursorWithWindow] = moveCursorWithWindow }
    }

    @Published var resizeWindowUnderCursor = Defaults[.resizeWindowUnderCursor] {
        didSet { Defaults[.resizeWindowUnderCursor] = resizeWindowUnderCursor }
    }

    @Published var focusWindowOnResize = Defaults[.focusWindowOnResize] {
        didSet { Defaults[.focusWindowOnResize] = focusWindowOnResize }
    }

    @Published var respectStageManager = Defaults[.respectStageManager] {
        didSet { Defaults[.respectStageManager] = respectStageManager }
    }

    @Published var stageStripSize = Defaults[.stageStripSize] {
        didSet { Defaults[.stageStripSize] = stageStripSize }
    }

    @Published var isPaddingConfigurationViewPresented = false

    let previewVisibility = Defaults[.previewVisibility]
    let systemSnappingWarning: LuminareInfoView = .init("macOS's \"Tile by dragging windows to screen edges\" feature is currently\nenabled, which will conflict with Loop's window snapping functionality.")
}

struct BehaviorConfigurationView: View {
    @StateObject private var model = BehaviorConfigurationModel()

    var body: some View {
        LuminareSection("General") {
            LuminareToggle("Launch at login", isOn: $model.launchAtLogin)
            LuminareToggle("Hide menu bar icon", isOn: $model.hideMenuBarIcon)
            LuminareSliderPicker(
                "Animation speed",
                AnimationConfiguration.allCases.reversed(),
                selection: $model.animationConfiguration
            ) {
                $0.name
            }
        }

        LuminareSection("Window") {
            LuminareToggle("Move window to cursor's screen", isOn: $model.useScreenWithCursor)

            if #available(macOS 15, *) {
                LuminareToggle(
                    "Window snapping",
                    info: SystemWindowManager.MoveAndResize.snappingEnabled ? model.systemSnappingWarning : nil,
                    isOn: $model.windowSnapping
                )
            } else {
                LuminareToggle("Window snapping", isOn: $model.windowSnapping)
            }

            // Enabling the system window manager will override these options anyway, so hide them
            if !model.useSystemWindowManagerWhenAvailable {
                LuminareToggle("Restore window frame on drag", isOn: $model.restoreWindowFrameOnDrag)
                LuminareToggle("Apply padding", isOn: $model.enablePadding)

                if model.enablePadding {
                    Button("Configure padding…") {
                        model.isPaddingConfigurationViewPresented = true
                    }
                    .luminareModal(isPresented: $model.isPaddingConfigurationViewPresented) {
                        PaddingConfigurationView(isPresented: $model.isPaddingConfigurationViewPresented)
                            .frame(width: 400)
                    }
                }
            }
        }
        .onReceive(.systemWindowManagerStateChanged) { _ in
            model.useSystemWindowManagerWhenAvailable = Defaults[.useSystemWindowManagerWhenAvailable]
        }

        LuminareSection("Cursor") {
            LuminareToggle(
                "Move cursor with window",
                info: model.previewVisibility ? nil : .init("Cannot be enabled when the preview is disabled."),
                isOn: $model.moveCursorWithWindow,
                disabled: !model.previewVisibility
            )
            LuminareToggle("Resize window under cursor", isOn: $model.resizeWindowUnderCursor)

            if model.resizeWindowUnderCursor {
                LuminareToggle("Focus window on resize", isOn: $model.focusWindowOnResize)
            }
        }

        LuminareSection("Stage Manager") {
            LuminareToggle("Respect Stage Manager", isOn: $model.respectStageManager)

            if model.respectStageManager {
                LuminareValueAdjuster(
                    "Stage strip size",
                    value: $model.stageStripSize,
                    sliderRange: 50...200,
                    suffix: "px",
                    lowerClamp: true
                )
            }
        }
    }
}

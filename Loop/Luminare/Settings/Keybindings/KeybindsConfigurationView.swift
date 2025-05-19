//
//  KeybindsConfigurationView.swift
//  Loop
//
//  Created by Kai Azim on 2024-04-20.
//

import Defaults
import Luminare
import SwiftUI

class KeybindsConfigurationModel: ObservableObject {
    @Published var triggerDelay = Defaults[.triggerDelay] {
        didSet { Defaults[.triggerDelay] = triggerDelay }
    }

    @Published var doubleClickToTrigger = Defaults[.doubleClickToTrigger] {
        didSet { Defaults[.doubleClickToTrigger] = doubleClickToTrigger }
    }

    @Published var middleClickTriggersLoop = Defaults[.middleClickTriggersLoop] {
        didSet { Defaults[.middleClickTriggersLoop] = middleClickTriggersLoop }
    }

    @Published var currentEventMonitor: NSEventMonitor?
    @Published var selectedKeybinds = Set<WindowAction>()
}

struct KeybindsConfigurationView: View {
    @StateObject private var model = KeybindsConfigurationModel()

    @Default(.triggerKey) var triggerKey
    @Default(.keybinds) var keybinds

    var body: some View {
        LuminareSection("Trigger Key", noBorder: true) {
            // TODO: Make long trigger keys fit in bounds
            TriggerKeycorder($triggerKey)
                .environmentObject(model)
        }

        LuminareSection("Settings") {
            LuminareValueAdjuster(
                "Trigger delay",
                value: $model.triggerDelay,
                sliderRange: 0...1,
                suffix: .init(.init(localized: "Measurement unit: seconds", defaultValue: "s")),
                step: 0.1,
                lowerClamp: true,
                decimalPlaces: 1
            )

            LuminareToggle("Double-click to trigger", isOn: $model.doubleClickToTrigger)
            LuminareToggle("Middle-click to trigger", isOn: $model.middleClickTriggersLoop)
        }

        LuminareList(
            "Keybinds",
            items: $keybinds,
            selection: $model.selectedKeybinds,
            addAction: {
                keybinds.insert(.init(.noAction), at: 0)
            },
            content: { keybind in
                KeybindItemView(keybind)
                    .environmentObject(model)
            },
            emptyView: {
                HStack {
                    Spacer()
                    VStack {
                        Text("No keybinds")
                            .font(.title3)
                        Text("Press \"Add\" to add a keybind")
                            .font(.caption)
                    }
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding()
            },
            id: \.id,
            addText: "Add",
            removeText: "Remove"
        )
    }
}

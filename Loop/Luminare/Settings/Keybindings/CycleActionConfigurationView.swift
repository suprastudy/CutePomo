//
//  CycleActionConfigurationView.swift
//  Loop
//
//  Created by Kai Azim on 2024-05-03.
//

import Defaults
import Luminare
import SwiftUI

struct CycleActionConfigurationView: View {
    @Binding var windowAction: WindowAction
    @Binding var isPresented: Bool

    @State private var action: WindowAction // this is so that onChange is called for each property

    @State private var selectedKeybinds = Set<WindowAction>()

    init(action: Binding<WindowAction>, isPresented: Binding<Bool>) {
        self._windowAction = action
        self._isPresented = isPresented
        self._action = State(initialValue: action.wrappedValue)
    }

    var body: some View {
        LuminareSection {
            LuminareTextField("Cycle Keybind", text: Binding(get: { action.name ?? "" }, set: { action.name = $0 }))
        }

        LuminareList(
            items: Binding(
                get: {
                    if action.cycle == nil {
                        action.cycle = []
                    }

                    return action.cycle ?? []
                }, set: { newValue in
                    action.cycle = newValue
                }
            ),
            selection: $selectedKeybinds,
            addAction: {
                if action.cycle == nil {
                    action.cycle = []
                }

                action.cycle?.insert(.init(.noAction), at: 0)
            },
            content: { item in
                KeybindItemView(
                    item,
                    cycleIndex: action.cycle?.firstIndex(of: item.wrappedValue)
                )
                .environmentObject(KeybindsConfigurationModel())
            },
            emptyView: {
                HStack {
                    Spacer()
                    VStack {
                        Text("Nothing to cycle through")
                            .font(.title3)
                        Text("Press \"Add\" to add a cycle item")
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
        .onChange(of: action) { _ in
            windowAction = action
        }

        Button("Close") {
            isPresented = false
        }
        .buttonStyle(LuminareCompactButtonStyle())
    }
}

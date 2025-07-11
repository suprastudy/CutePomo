import SwiftUI
import AppKit

struct PomodoroPreset: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var work: Int
    var brk: Int
    var isDefault: Bool = false
}

// Componente para un preset individual - Versión mejorada
struct PresetRow: View {
    let preset: PomodoroPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(preset.label)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    if preset.isDefault {
                        Text("Default")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Label {
                        Text("\(preset.work / 60) min")
                            .font(.system(size: 12))
                    } icon: {
                        Image(systemName: "timer")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label {
                        Text("\(preset.brk / 60) min break")
                            .font(.system(size: 12))
                    } icon: {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 16, height: 16)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 20)
            
            if !preset.isDefault && onEdit != nil && onDelete != nil {
                HStack(spacing: 8) {
                    Button(action: {
                        onEdit?()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.blue.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Edit preset")
                    
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.red.opacity(0.8))
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Delete preset")
                }
                .opacity(isHovering ? 1.0 : 0.6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected 
                      ? Color.blue.opacity(0.08) 
                      : (isHovering ? Color(.unemphasizedSelectedContentBackgroundColor).opacity(0.3) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected 
                        ? Color.blue.opacity(0.3) 
                        : Color.clear,
                        lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture(perform: onSelect)
    }
}

// Componente para la lista de presets
struct PresetsList: View {
    let presets: [PomodoroPreset]
    let selectedPreset: String
    let onPresetSelected: (PomodoroPreset) -> Void
    let onEditPreset: (PomodoroPreset) -> Void
    let onDeletePreset: (PomodoroPreset) -> Void
    let onCreatePreset: () -> Void
    
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var showScrollIndicator: Bool = true
    @State private var presetsCount: Int = 0
    
    // Valor más confiable para rastrear el desplazamiento
    @State private var hasScrolled: Bool = false
    
    var body: some View {
        if presets.isEmpty {
            emptyStateView
        } else {
            ZStack(alignment: .bottom) {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 6) {
                            ForEach(presets) { preset in
                                PresetRow(
                                    preset: preset,
                                    isSelected: selectedPreset == preset.label,
                                    onSelect: { onPresetSelected(preset) },
                                    onEdit: !preset.isDefault ? { onEditPreset(preset) } : nil,
                                    onDelete: !preset.isDefault ? { onDeletePreset(preset) } : nil
                                )
                                .id(preset.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(GeometryReader { geo in
                            Color.clear.onAppear {
                                self.contentHeight = geo.size.height
                                self.scrollViewProxy = proxy
                                self.showScrollIndicator = true
                                self.hasScrolled = false
                            }
                            .onChange(of: geo.size.height) { _, newHeight in
                                self.contentHeight = newHeight
                            }
                        })
                    }
                }
                .onAppear {
                    // Reiniciar el estado de desplazamiento cuando la vista aparece
                    hasScrolled = false
                    showScrollIndicator = true
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        self.scrollViewHeight = geo.size.height
                    }
                    .onChange(of: geo.size.height) { _, newHeight in
                        self.scrollViewHeight = newHeight
                    }
                })
                // Usar la preferencia de NSScrollView para detectar el desplazamiento
                .onReceive(NotificationCenter.default.publisher(for: NSScrollView.willStartLiveScrollNotification)) { _ in
                    // Cuando el usuario comienza a desplazarse
                    withAnimation {
                        self.hasScrolled = true
                        self.showScrollIndicator = false
                    }
                }
                // Respaldo: usar un gesto para detectar movimiento
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in
                            if !hasScrolled {
                                self.hasScrolled = true
                                withAnimation {
                                    self.showScrollIndicator = false
                                }
                            }
                        }
                )
                .onChange(of: presets.count) { _, newCount in
                    // Si el número de presets cambia, volvemos a mostrar el indicador
                    if presetsCount != newCount {
                        self.hasScrolled = false
                        self.showScrollIndicator = true
                        presetsCount = newCount
                    }
                }
                .onAppear {
                    presetsCount = presets.count
                }
                
                // Indicador de scroll mejorado (flecha hacia abajo)
                if contentHeight > scrollViewHeight && presets.count > 0 && showScrollIndicator && !hasScrolled {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            // Desplazar hacia el siguiente preset que no es visible
                            let approximatePresetHeight: CGFloat = 50 // Altura aproximada de cada preset
                            let lastVisibleIndex = Int(scrollViewHeight / approximatePresetHeight)
                            
                            if lastVisibleIndex < presets.count - 1 {
                                scrollViewProxy?.scrollTo(presets[min(lastVisibleIndex + 1, presets.count - 1)].id, anchor: .top)
                            } else if presets.count > 0 {
                                // Si no podemos calcular bien, simplemente ir al último
                                scrollViewProxy?.scrollTo(presets.last!.id, anchor: .bottom)
                            }
                            
                            // Ocultar el indicador después de presionar
                            self.hasScrolled = true
                            self.showScrollIndicator = false
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.secondary)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                            .background(
                                Circle()
                                    .fill(Color(.controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.bottom, 8)
                    .animation(.easeInOut(duration: 0.2), value: scrollOffset)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "timer.circle")
                .font(.system(size: 40))
                .foregroundColor(Color.blue.opacity(0.7))
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text("No Presets Available")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create your first timer preset to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onCreatePreset) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Preset")
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Header para la sección de presets - Versión mejorada
struct PresetsHeader: View {
    let title: String
    let onNewPressed: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onNewPressed) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                    
                    Text("New Preset")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// Componente para estilizar toggles con el mismo estilo visual
struct ToggleStyleView: View {
    let title: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.7 : 0.9
    }
    
    private var borderOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.25
    }
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .blue : .gray)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(backgroundOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(borderOpacity), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Componente para selección de posición del botón de cierre con el mismo estilo que ShapeSelectorView
struct CloseButtonPositionSelectorView: View {
    enum CloseButtonPosition: String, CaseIterable {
        case left = "< Left >"
        case right = "< Right >"

        mutating func toggle() {
            self = CloseButtonPosition.allCases.first(where: { $0 != self })!
        }
    }

    @Binding var position: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentPosition: CloseButtonPosition {
        position == "left" ? .left : .right
    }
    
    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.15 : 0.08
    }
    
    private var borderOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.25
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                position = position == "left" ? "right" : "left"
            }) {
                HStack {
                    Text("Close button position")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(currentPosition.rawValue)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(colorScheme == .dark ? 0.7 : 0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(borderOpacity), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 0)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView: View {
    @AppStorage("workDuration") private var workDuration: Int = 25 * 60
    @AppStorage("breakDuration") private var breakDuration: Int = 5 * 60
    @AppStorage("selectedPreset") private var selectedPreset: String = "25:05 (Classic)"
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false
    @AppStorage("monospacedFont") private var monospacedFont: Bool = false
    @AppStorage("showDoubleClickText") private var showDoubleClickText: Bool = true
    @AppStorage("closeButtonPosition") private var closeButtonPosition: String = "left"
    @AppStorage("workColorRed") private var workColorRed: Double = 0.91
    @AppStorage("workColorGreen") private var workColorGreen: Double = 0.49
    @AppStorage("workColorBlue") private var workColorBlue: Double = 0.45
    @AppStorage("breakColorRed") private var breakColorRed: Double = 0.47
    @AppStorage("breakColorGreen") private var breakColorGreen: Double = 0.67
    @AppStorage("breakColorBlue") private var breakColorBlue: Double = 0.62
    
    @State private var presets: [PomodoroPreset] = []
    @State private var editingPreset: PomodoroPreset?
    @State private var editWorkDuration: Int = 25 * 60
    @State private var editBreakDuration: Int = 5 * 60
    @State private var showingEditSheet: Bool = false
    @State private var showingCreateSheet: Bool = false
    
    private let defaultPresets = [
        PomodoroPreset(label: "25:05 (Classic)", work: 25 * 60, brk: 5 * 60, isDefault: true),
        PomodoroPreset(label: "50:10 (Extended)", work: 50 * 60, brk: 10 * 60, isDefault: true),
        PomodoroPreset(label: "15:03 (Short)", work: 15 * 60, brk: 3 * 60, isDefault: true)
    ]
    
    var body: some View {
        TabView {
            // GENERAL TAB
            generalTab
            
            // PRESETS TAB
            presetsTab
            
            // ABOUT TAB
            aboutTab
            

        }
        .frame(width: 500, height: 350)
        // Edit Sheet
        .sheet(isPresented: $showingEditSheet) {
            if let preset = editingPreset {
                EditPresetView(
                    isPresented: $showingEditSheet,
                    preset: preset,
                    workDuration: editWorkDuration,
                    breakDuration: editBreakDuration,
                    onSave: { newName, workDuration, breakDuration in
                        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
                            // Actualizar el nombre y las duraciones
                            presets[index].label = newName
                            presets[index].work = workDuration
                            presets[index].brk = breakDuration
                            
                            // Actualizar preset seleccionado si era el que se editó
                            if selectedPreset == preset.label {
                                selectedPreset = newName
                                self.workDuration = workDuration
                                self.breakDuration = breakDuration
                            }
                            
                            savePresets()
                        }
                    }
                )
            }
        }
        // Create Sheet
        .sheet(isPresented: $showingCreateSheet) {
            CreatePresetView(
                isPresented: $showingCreateSheet,
                currentWorkDuration: workDuration,
                currentBreakDuration: breakDuration,
                onSave: { presetName, workDuration, breakDuration in
                    let newPreset = PomodoroPreset(
                        label: presetName,
                        work: workDuration,
                        brk: breakDuration,
                        isDefault: false
                    )
                    presets.append(newPreset)
                    savePresets()
                }
            )
        }
        .onAppear {
            loadPresets()
        }
    }
    
    // MARK: - Tab Views
    
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox(label: Label("Appearance", systemImage: "paintbrush")
                    .font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        ShapeSelectorView(isMonospaced: $monospacedFont)
                        
                        ToggleStyleView(title: "Keep window always on top", isOn: $alwaysOnTop)
                        
                        ToggleStyleView(title: "Show 'double click to switch' instruction", isOn: $showDoubleClickText)
                        
                        // Close button position setting
                        CloseButtonPositionSelectorView(position: $closeButtonPosition)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                }
                
                GroupBox(label: Label("Color", systemImage: "paintpalette")
                    .font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        ColorSelectorView(
                            title: "Work Timer Color",
                            red: $workColorRed,
                            green: $workColorGreen,
                            blue: $workColorBlue
                        )
                        
                        ColorSelectorView(
                            title: "Break Timer Color",
                            red: $breakColorRed,
                            green: $breakColorGreen,
                            blue: $breakColorBlue
                        )
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 10)
                }
                
                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .tabItem {
            Label("General", systemImage: "gearshape")
        }
    }
    
    private var presetsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            presetsContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabItem {
                Label("Presets", systemImage: "square.grid.2x2")
            }
            .padding(20)
        .onChange(of: showingEditSheet) { _, newValue in
            if !newValue {
                editingPreset = nil
            }
        }
    }
    
    private var aboutTab: some View {
            VStack(spacing: 20) {
                // App icon using Icon-mac-512
                Image("Icon-mac-512")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Cutepomo")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Text("A beautiful, minimal pomodoro timer")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Text("Focus on your work with style")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Made with ❤️ by Matias Sandoval")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Social media links
                    HStack(spacing: 16) {
                        Link(destination: URL(string: "https://instagram.com/matijrn")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                Text("@matijrn")
                            }
                            .font(.caption)
                            .foregroundColor(.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Link(destination: URL(string: "https://twitter.com/matijrn")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "bird.fill")
                                Text("@matijrn")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("© 2024 Cutepomo")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                //.padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
    
    // MARK: - Preset Container View
    
    private var presetsContainer: some View {
        VStack(alignment: .leading, spacing: 0) {
            PresetsHeader(
                title: "Saved Presets", 
                onNewPressed: { showingCreateSheet = true }
            )
            
            Divider()
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                PresetsList(
                    presets: presets,
                    selectedPreset: selectedPreset,
                    onPresetSelected: { preset in
                        selectedPreset = preset.label
                        workDuration = preset.work
                        breakDuration = preset.brk
                    },
                    onEditPreset: { preset in
                        editingPreset = preset
                        editWorkDuration = preset.work
                        editBreakDuration = preset.brk
                        showingEditSheet = true
                    },
                    onDeletePreset: { preset in
                        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
                            presets.remove(at: index)
                            savePresets()
                        }
                    },
                    onCreatePreset: { showingCreateSheet = true }
                )
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor).opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Data Functions
    
    private func savePresets() {
        // Filter out default presets before saving
        let customPresets = presets.filter { !$0.isDefault }
        
        if let encodedData = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encodedData, forKey: "savedPresets")
        }
    }
    
    private func loadPresets() {
        // Start with default presets
        presets = defaultPresets
        
        // Add saved custom presets
        if let savedData = UserDefaults.standard.data(forKey: "savedPresets"),
           let customPresets = try? JSONDecoder().decode([PomodoroPreset].self, from: savedData) {
            presets.append(contentsOf: customPresets)
        }
    }
}

struct EditPresetView: View {
    @Binding var isPresented: Bool
    let preset: PomodoroPreset
    @State var workDuration: Int
    @State var breakDuration: Int
    @State private var presetName: String
    let onSave: (String, Int, Int) -> Void
    
    init(isPresented: Binding<Bool>, preset: PomodoroPreset, workDuration: Int, breakDuration: Int, onSave: @escaping (String, Int, Int) -> Void) {
        self._isPresented = isPresented
        self.preset = preset
        self._workDuration = State(initialValue: workDuration)
        self._breakDuration = State(initialValue: breakDuration)
        self._presetName = State(initialValue: preset.label)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 10) {
                Text("Edit Preset")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Preset Name")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("Enter preset name", text: $presetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Work Duration:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(workDuration / 60) minutes")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("5 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(workDuration / 60) },
                        set: { workDuration = Int($0) * 60 }
                    ), in: 1...120, step: 1)
                    .accentColor(.blue)
                    
                    Text("120 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.green)
                    Text("Break Duration:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(breakDuration / 60) minutes")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("1 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(breakDuration / 60) },
                        set: { breakDuration = Int($0) * 60 }
                    ), in: 1...30, step: 1)
                    .accentColor(.green)
                    
                    Text("30 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Save Changes") {
                    onSave(presetName, workDuration, breakDuration)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

struct CreatePresetView: View {
    @Binding var isPresented: Bool
    let currentWorkDuration: Int
    let currentBreakDuration: Int
    
    @State private var presetName: String = ""
    @State private var workDuration: Int = 25 * 60
    @State private var breakDuration: Int = 5 * 60
    
    let onSave: (String, Int, Int) -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Create New Preset")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Preset Name")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("Enter preset name", text: $presetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Work Duration:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(workDuration / 60) minutes")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("5 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(workDuration / 60) },
                        set: { workDuration = Int($0) * 60 }
                    ), in: 1...120, step: 1)
                    .accentColor(.blue)
                    
                    Text("120 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.green)
                    Text("Break Duration:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(breakDuration / 60) minutes")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("1 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(breakDuration / 60) },
                        set: { breakDuration = Int($0) * 60 }
                    ), in: 1...30, step: 1)
                    .accentColor(.green)
                    
                    Text("30 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 15) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Create Preset") {
                    if !presetName.isEmpty {
                        onSave(presetName, workDuration, breakDuration)
                        isPresented = false
                    }
                }
                .disabled(presetName.isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

// Componente para selección de colores
struct ColorSelectorView: View {
    let title: String
    @Binding var red: Double
    @Binding var green: Double
    @Binding var blue: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentColor: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    private var backgroundOpacity: Double {
        colorScheme == .dark ? 0.7 : 0.9
    }
    
    private var borderOpacity: Double {
        colorScheme == .dark ? 0.4 : 0.25
    }
    
    // Colores predefinidos
    private let predefinedColors: [(String, Double, Double, Double)] = [
        ("Red", 0.91, 0.49, 0.45),
        ("Green", 0.47, 0.67, 0.62),
        ("Blue", 0.2, 0.6, 0.86),
        ("Purple", 0.68, 0.46, 0.82),
        ("Orange", 0.96, 0.65, 0.14),
        ("Pink", 0.96, 0.41, 0.64),
        ("Yellow", 0.98, 0.84, 0.25),
        ("Indigo", 0.35, 0.34, 0.84)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            // Fila de colores predefinidos
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                ForEach(predefinedColors, id: \.0) { colorData in
                    let (_, r, g, b) = colorData
                    let color = Color(red: r, green: g, blue: b)
                    let isSelected = abs(red - r) < 0.01 && abs(green - g) < 0.01 && abs(blue - b) < 0.01
                    
                    Button(action: {
                        red = r
                        green = g
                        blue = b
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.primary : Color.gray.opacity(0.3), 
                                           lineWidth: isSelected ? 2 : 1)
                            )
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.1), value: isSelected)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(backgroundOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(borderOpacity), lineWidth: 1)
        )
    }
}

#Preview {
    SettingsView()
}


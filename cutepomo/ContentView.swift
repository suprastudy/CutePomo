import SwiftUI
import AppKit

struct ContentView: View {
    @AppStorage("monospacedFont") private var monospacedFont: Bool = false
    @State private var isHovered = false
    @AppStorage("showDoubleClickText") private var showDoubleClickText: Bool = true
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false
    @AppStorage("closeButtonPosition") private var closeButtonPosition: String = "right"

    @State private var timeRemaining = 25 * 60
    @State private var timer: Timer? = nil
    @State private var isActive = false
    @State private var currentMode: TimerMode = .work
    @State private var hoverTimer: Timer? = nil
    @State private var didShowTimeUp = false

    @AppStorage("workDuration") private var workTime: Int = 25 * 60
    @AppStorage("breakDuration") private var breakTime: Int = 5 * 60
    @AppStorage("workColorRed") private var workColorRed: Double = 0.91
    @AppStorage("workColorGreen") private var workColorGreen: Double = 0.49
    @AppStorage("workColorBlue") private var workColorBlue: Double = 0.45
    @AppStorage("breakColorRed") private var breakColorRed: Double = 0.47
    @AppStorage("breakColorGreen") private var breakColorGreen: Double = 0.67
    @AppStorage("breakColorBlue") private var breakColorBlue: Double = 0.62

    // Propiedad computada para obtener el color del modo actual
    private var currentModeColor: Color {
        currentMode.color(
            workColorRed: workColorRed,
            workColorGreen: workColorGreen,
            workColorBlue: workColorBlue,
            breakColorRed: breakColorRed,
            breakColorGreen: breakColorGreen,
            breakColorBlue: breakColorBlue
        )
    }

    enum TimerMode {
        case work
        case break_

        func color(workColorRed: Double, workColorGreen: Double, workColorBlue: Double,
                  breakColorRed: Double, breakColorGreen: Double, breakColorBlue: Double) -> Color {
            switch self {
            case .work: return Color(red: workColorRed, green: workColorGreen, blue: workColorBlue)
            case .break_: return Color(red: breakColorRed, green: breakColorGreen, blue: breakColorBlue)
            }
        }

        var title: String {
            switch self {
            case .work: return ""
            case .break_: return ""
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // El área de hover abarca todo (X y temporizador)
                VStack(spacing: 0) {
                    if isHovered {
                        VStack(spacing: 0) {
                            Spacer(minLength: 62) // mienrtas mas grande el numero, mas abajo está
                            HStack(spacing: 0) {
                                if closeButtonPosition == "left" {
                                    Spacer(minLength: 25)  // Espacio desde el borde izquierdo
                                    Button(action: {
                                        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
                                            window.orderOut(nil)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 18, weight: .bold))
                                            .opacity(0.45)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 28, height: 28, alignment: .topLeading)
                                    .allowsHitTesting(true)
                                    Spacer(minLength: 130)  // El resto del espacio hacia la derecha
                                } else {
                                    Spacer(minLength: 120)  //en 150 se lo ve muy a la derecha
                                    Button(action: {
                                        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainAppWindow" }) {
                                            window.orderOut(nil)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 18, weight: .bold))
                                            .opacity(0.45)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 28, height: 28, alignment: .topLeading)
                                    .allowsHitTesting(true)
                                }
                            }
                            Spacer(minLength: 30)
                        }
                        .frame(height: 0)
                    }
                    // El temporizador siempre está alineado arriba, sin espacio extra si no hay X
                    ZStack {
                        VStack(spacing: 4) {
                            // Mode indicator - only show if there's text
                            if !currentMode.title.isEmpty {
                                Text(currentMode.title)
                                    .font(.system(size: 12, weight: .medium, design: monospacedFont ? .monospaced : .rounded))
                                    .foregroundColor(currentModeColor.opacity(0.8))
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(
                                        Capsule()
                                            .fill(currentModeColor.opacity(0.15))
                                    )
                            }
                            
                            // Timer text
                            Text(timeString)
                                .font(.system(size: 30, weight: .bold, design: monospacedFont ? .monospaced : .rounded))
                                .foregroundStyle(.primary)
                        }
                        .frame(height: 60) // Reducir la altura para adaptarse al diseño sin indicador de modo
                        .frame(maxWidth: .infinity)
                        .onTapGesture(count: 2) {
                            switchMode()
                        }
                        .help("Double-click to switch mode")
                    }
                    // Los controles aparecen debajo, pero no afectan la posición del temporizador
                    ZStack {
                        if isHovered {
                            VStack {
                                if showDoubleClickText {
                                    HStack {
                                        Text("double click to switch")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(.bottom, -8)
                                }
                                HStack(spacing: 16) {
                                    controlButton(systemName: isActive ? "pause.fill" : "play.fill", action: toggleTimer, color: currentModeColor)
                                    controlButton(systemName: "arrow.counterclockwise", action: resetTimer, color: .secondary)
                                }
                                .padding(.top, 0)
                                .padding(.bottom, 8)
                            }
                        } else {
                            // Espacio vacío para mantener la altura constante
                            Color.clear.frame(height: 0)
                        }
                    }
                    .frame(height: isHovered ? 40 : 0) // Ajusta la altura del área de controles
                }
                .frame(width: 140)
                .padding(.vertical, 0) // El padding vertical ya no afecta la posición del temporizador
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: isActive ? 5 : 2)
                )
                .overlay(
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(currentModeColor.opacity(0.6))
                            .frame(width: geometry.size.width * progress, height: 2)
                            .padding(.top, 1)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                )
                .contentShape(Rectangle())
                .onHover(perform: onHoverChanged)
                .gesture(dragGesture)
                .help("Click anywhere to start/pause")
                .onAppear {
                    configureWindow()
                    setupNotificationObservers()
                }
                .onDisappear {
                    removeNotificationObservers()
                }
                .onChange(of: workTime) {
                    if currentMode == .work {
                        timeRemaining = workTime
                        isActive = false
                        timer?.invalidate()
                        timer = nil
                    }
                }
                .onChange(of: breakTime) {
                    if currentMode == .break_ {
                        timeRemaining = breakTime
                        isActive = false
                        timer?.invalidate()
                        timer = nil
                    }
                }
                // Cierra VStack principal
                }
            
        }
    }

    private func setupNotificationObservers() {
        // Add observers for keyboard shortcuts
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ToggleTimer"),
            object: nil,
            queue: .main
        ) { _ in
            toggleTimer()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ResetTimer"),
            object: nil,
            queue: .main
        ) { _ in
            resetTimer()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SwitchTimerMode"),
            object: nil,
            queue: .main
        ) { _ in
            switchMode()
        }
        

        

    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ToggleTimer"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ResetTimer"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SwitchTimerMode"), object: nil)
    }

    @ViewBuilder
    private func controlButton(systemName: String, action: @escaping () -> Void, color: Color) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }

    private func onHoverChanged(_ hovering: Bool) {
        hoverTimer?.invalidate()

        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            if hovering != isHovered {
                isHovered = hovering
                DispatchQueue.main.async {
                    updateWindowSize(expanded: hovering)
                }
            }
        }
    }

    private func configureWindow() {
        DispatchQueue.main.async {
            updateWindowSize(expanded: false)
        }
    }

    private var tapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { _ in
                toggleTimer()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
            }
    }

    private var progress: Double {
        let total = currentMode == .work ? Double(workTime) : Double(breakTime)
        guard total > 0, total.isFinite else { return 0 }
        
        let value = 1.0 - (Double(timeRemaining) / total)
        return min(max(value, 0), 1)
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func toggleTimer() {
        if isActive {
            timer?.invalidate()
            timer = nil
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else if !didShowTimeUp {
                    timer?.invalidate()
                    timer = nil
                    isActive = false
                    didShowTimeUp = true
                    handleTimerCompletion()
                }
            })
            RunLoop.current.add(timer!, forMode: .common)
        }
        isActive.toggle()
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        timeRemaining = currentMode == .work ? workTime : breakTime
        didShowTimeUp = false
    }

    private func switchMode() {
        currentMode = (currentMode == .work) ? .break_ : .work
        timeRemaining = (currentMode == .work) ? workTime : breakTime
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    private func toggleTitleBarVisibility(visible: Bool) {
        // No hacemos nada aquí, ya que los botones siempre deben estar ocultos
    }

    private func updateWindowSize(expanded: Bool) {
        guard let window = NSApp.windows.first else { return }

        let newHeight: CGFloat = expanded ? 130 : 70
        let currentHeight = window.frame.height

        if abs(currentHeight - newHeight) > 1 {
            let currentFrame = window.frame
            let newOriginY = currentFrame.origin.y - (newHeight - currentFrame.height)

            let newRect = NSRect(
                x: currentFrame.origin.x,
                y: newOriginY,
                width: currentFrame.width,
                height: newHeight
            )

            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0
            window.setFrame(newRect, display: true)
            NSAnimationContext.endGrouping()
        }
    }

    // Timer completion handler
    private func handleTimerCompletion() {
        // Reproducir el sonido de notificación
        NSSound.beep()
        
        // Auto-switch to the next mode
        switchMode()
    }


    

}

import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @AppStorage("monospacedFont") private var monospacedFont: Bool = false
    @State private var isHovered = false
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage("showDoubleClickText") private var showDoubleClickText: Bool = true
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false

    @State private var timeRemaining = 25 * 60
    @State private var timer: Timer? = nil
    @State private var isActive = false
    @State private var currentMode: TimerMode = .work
    @State private var hoverTimer: Timer? = nil
    @State private var didShowTimeUp = false

    @AppStorage("workDuration") private var workTime: Int = 25 * 60
    @AppStorage("breakDuration") private var breakTime: Int = 5 * 60

    enum TimerMode {
        case work
        case break_

        var color: Color {
            switch self {
            case .work: return Color(red: 0.91, green: 0.49, blue: 0.45)
            case .break_: return Color(red: 0.47, green: 0.67, blue: 0.62)
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
                                    .foregroundColor(currentMode.color.opacity(0.8))
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(
                                        Capsule()
                                            .fill(currentMode.color.opacity(0.15))
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
                                    controlButton(systemName: isActive ? "pause.fill" : "play.fill", action: toggleTimer, color: currentMode.color)
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
                            .fill(currentMode.color.opacity(0.6))
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
                .onChange(of: workTime) { _ in
                    if currentMode == .work {
                        timeRemaining = workTime
                        isActive = false
                        timer?.invalidate()
                        timer = nil
                    }
                }
                .onChange(of: breakTime) { _ in
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
        
        // Add observers for TimeUpView interactions
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StartBreakTimer"),
            object: nil,
            queue: .main
        ) { _ in
            startBreakTimer()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StartWorkTimer"),
            object: nil,
            queue: .main
        ) { _ in
            startWorkTimer()
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ToggleTimer"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ResetTimer"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SwitchTimerMode"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("StartBreakTimer"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("StartWorkTimer"), object: nil)
    }

    @ViewBuilder
    private func controlButton(systemName: String, action: @escaping () -> Void, color: Color) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .background(
                    Circle()
                        .fill(.thinMaterial)
                )
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
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
                if let window = NSApp.windows.first {
                    let currentPosition = window.frame.origin
                    let newPosition = NSPoint(
                        x: currentPosition.x + gesture.location.x - gesture.startLocation.x,
                        y: currentPosition.y - gesture.location.y + gesture.startLocation.y
                    )
                    window.setFrameOrigin(newPosition)
                }
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
                    showTimeUpWindow()
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

    // Abre una nueva ventana con TimeUpView
    private func showTimeUpWindow() {
        let timeUpWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 340),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        timeUpWindow.center()
        timeUpWindow.contentView = NSHostingView(rootView: TimeUpView())
        timeUpWindow.isMovableByWindowBackground = true
        timeUpWindow.titleVisibility = .hidden
        timeUpWindow.titlebarAppearsTransparent = true
        timeUpWindow.standardWindowButton(.closeButton)?.isHidden = true
        timeUpWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        timeUpWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Redondear la ventana físicamente
        if let contentView = timeUpWindow.contentView?.superview {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 14
            contentView.layer?.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
            contentView.layer?.masksToBounds = true
        }
        
        timeUpWindow.makeKeyAndOrderFront(nil)
        
        // Reproducir el sonido de notificación
        NSSound.beep()
    }

    // Helper methods for TimeUpView interactions
    private func startBreakTimer() {
        if currentMode != .break_ {
            currentMode = .break_
        }
        timeRemaining = breakTime
        isActive = true
        didShowTimeUp = false
        
        // Start the timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else if !self.didShowTimeUp {
                self.timer?.invalidate()
                self.timer = nil
                self.isActive = false
                self.didShowTimeUp = true
                self.showTimeUpWindow()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func startWorkTimer() {
        if currentMode != .work {
            currentMode = .work
        }
        timeRemaining = workTime
        isActive = true
        didShowTimeUp = false
        
        // Start the timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else if !self.didShowTimeUp {
                self.timer?.invalidate()
                self.timer = nil
                self.isActive = false
                self.didShowTimeUp = true
                self.showTimeUpWindow()
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
}

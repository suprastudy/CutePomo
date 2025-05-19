import SwiftUI

struct LicenseActivationView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var licenseKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var onActivationSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            
            Text("Activar cutepomo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if licenseManager.isTrialActive {
                Text("Período de prueba: \(licenseManager.trialDaysRemaining) días restantes")
                    .foregroundColor(.secondary)
            } else {
                Text("Tu período de prueba ha terminado")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingresa tu clave de licencia:")
                    .font(.headline)
                
                TextField("Ingresa tu clave de licencia", text: $licenseKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                
                Text("Puedes adquirir una licencia en nuestra página web.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Comprar licencia") {
                    // Abrir la página de compra
                    if let url = URL(string: "https://cutepomo.lemonsqueezy.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }
            .padding()
            
            HStack(spacing: 16) {
                Button("Activar") {
                    activateLicense()
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.isEmpty || licenseManager.isActivating)
                
                if licenseManager.isActivating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, -10)
                }
            }
            
            if let errorMessage = licenseManager.lastErrorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Activación exitosa" : "Error de activación"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        onActivationSuccess()
                    }
                }
            )
        }
    }
    
    private func activateLicense() {
        licenseManager.activateLicense(key: licenseKey) { success, message in
            self.isSuccess = success
            self.alertMessage = message
            self.showAlert = true
        }
    }
}

#Preview {
    LicenseActivationView(onActivationSuccess: {})
} 
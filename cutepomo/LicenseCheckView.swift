import SwiftUI

struct LicenseCheckView<Content: View>: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var showActivationView = false
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if licenseManager.isAppUnlocked() {
                content
                    .onAppear {
                        // Verificar periódicamente el estado de la licencia
                        if !licenseManager.licenseKey.isEmpty {
                            licenseManager.verifyLicense(key: licenseManager.licenseKey)
                        }
                    }
            } else {
                LicenseActivationView(onActivationSuccess: {
                    // Ocultar la vista de activación cuando se active con éxito
                    showActivationView = false
                })
            }
        }
        .onAppear {
            // Verificar el estado de la licencia cuando aparece la vista
            licenseManager.checkTrialStatus()
            showActivationView = !licenseManager.isAppUnlocked()
        }
    }
}

#Preview {
    LicenseCheckView {
        Text("Contenido de la aplicación")
            .frame(width: 300, height: 200)
    }
} 
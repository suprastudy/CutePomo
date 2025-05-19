import SwiftUI

struct LicenseSettingsView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var showResetAlert = false
    @State private var showActivationView = false
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var showActivationAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Licence")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if licenseManager.isValidLicense {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        
                        Text("Licence Active")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Key: \(licenseManager.licenseKey.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                    Text("Activations: \(licenseManager.activationUsage)/\(licenseManager.activationLimit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if licenseManager.isTrialActive {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                        
                        Text("Trial period")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("\(licenseManager.trialDaysRemaining) days remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text("Trial period ended")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.windowBackgroundColor).opacity(0.7))
            .cornerRadius(8)
            
            if !licenseManager.isValidLicense {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your licence key:")
                        .font(.headline)
                    
                    TextField("Enter your licence key", text: $licenseKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack(spacing: 16) {
                        Button("Activate") {
                            activateLicense()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(licenseKey.isEmpty || isActivating)
                        
                        if isActivating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.leading, -10)
                        }
                        
                        Spacer()
                        
                        Button("Buy Licence") {
                            if let url = URL(string: "https://cutepomo.lemonsqueezy.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                    
                    if let errorMessage = licenseManager.lastErrorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.windowBackgroundColor).opacity(0.7))
                .cornerRadius(8)
            } else {
                HStack {
                    Button("Deactivate Licence") {
                        showResetAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Spacer()
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            Text("Lifetime licence for 1 device")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Get a licence to unlock access to all features. During the 3-day trial period, you have full access to all features.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity)
        // Alert to confirm licence deletion
        .alert("Delete licence?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                licenseManager.resetLicense()
            }
        } message: {
            Text("Are you sure you want to delete your licence from this device? You'll need to activate it again.")
        }
        // Alert to show activation results
        .alert(isPresented: $showActivationAlert) {
            Alert(
                title: Text(isSuccess ? "Activation successful" : "Activation error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func activateLicense() {
        isActivating = true
        licenseManager.activateLicense(key: licenseKey) { success, message in
            self.isSuccess = success
            self.alertMessage = message
            self.showActivationAlert = true
            self.isActivating = false
            
            if success {
                self.licenseKey = ""
            }
        }
    }
}

#Preview {
    LicenseSettingsView()
        .frame(width: 400)
} 
import Foundation
import Combine

class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    @Published var isValidLicense = false
    @Published var isTrialActive = false
    @Published var trialDaysRemaining = 0
    @Published var licenseKey = ""
    @Published var isActivating = false
    @Published var lastErrorMessage: String?
    @Published var activationLimit = 0
    @Published var activationUsage = 0
    
    private let userDefaults = UserDefaults.standard
    private let trialLengthDays = 3
    private let licenseKeyKey = "licenseKey"
    private let firstLaunchDateKey = "firstLaunchDate"
    private let deviceIdentifierKey = "deviceIdentifier"
    private let instanceIdKey = "instanceId"
    
    private let lemonSqueezyService = LemonSqueezyService.shared
    
    init() {
        // Cargar la clave de licencia guardada si existe
        if let savedKey = userDefaults.string(forKey: licenseKeyKey) {
            licenseKey = savedKey
            
            // Restaurar el ID de instancia si existe
            if let savedInstanceId = userDefaults.string(forKey: instanceIdKey) {
                lemonSqueezyService.restoreInstanceId(savedInstanceId)
                // Si tenemos un ID de instancia guardado, asumimos que la licencia es válida inicialmente
                isValidLicense = true
            }
            
            // Verificar la licencia almacenada solo si no tenemos un ID de instancia
            if lemonSqueezyService.getCurrentInstanceId() == nil {
                verifyLicense(key: savedKey)
            }
        } else {
            // Comprobar el estado del período de prueba
            checkTrialStatus()
        }
        
        // Generar o recuperar el identificador único del dispositivo
        if userDefaults.string(forKey: deviceIdentifierKey) == nil {
            userDefaults.set(UUID().uuidString, forKey: deviceIdentifierKey)
        }
    }
    
    func saveFirstLaunchDateIfNeeded() {
        if userDefaults.object(forKey: firstLaunchDateKey) == nil {
            userDefaults.set(Date(), forKey: firstLaunchDateKey)
        }
    }
    
    func checkTrialStatus() {
        saveFirstLaunchDateIfNeeded()
        
        guard let firstLaunchDate = userDefaults.object(forKey: firstLaunchDateKey) as? Date else {
            isTrialActive = true
            trialDaysRemaining = trialLengthDays
            return
        }
        
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        trialDaysRemaining = max(0, trialLengthDays - daysPassed)
        isTrialActive = trialDaysRemaining > 0
    }
    
    func activateLicense(key: String, completion: @escaping (Bool, String) -> Void) {
        // Guardamos la clave para usarla más tarde
        self.licenseKey = key
        self.isActivating = true
        self.lastErrorMessage = nil
        
        let deviceId = getDeviceIdentifier()
        
        lemonSqueezyService.validateLicense(key: key, deviceIdentifier: deviceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isActivating = false
                
                switch result {
                case .success((let isValid, let limit, let usage)):
                    if isValid {
                        self.userDefaults.set(key, forKey: self.licenseKeyKey)
                        // Guardar el ID de instancia si está disponible
                        if let instanceId = self.lemonSqueezyService.getCurrentInstanceId() {
                            self.userDefaults.set(instanceId, forKey: self.instanceIdKey)
                        }
                        self.isValidLicense = true
                        self.activationLimit = limit
                        self.activationUsage = usage
                        completion(true, "Licencia activada correctamente")
                    } else {
                        self.isValidLicense = false
                        let errorMsg = "La licencia no pudo ser validada"
                        self.lastErrorMessage = errorMsg
                        completion(false, errorMsg)
                    }
                    
                case .failure(let error):
                    self.isValidLicense = false
                    self.lastErrorMessage = error.description
                    completion(false, error.description)
                }
            }
        }
    }
    
    func verifyLicense(key: String) {
        let deviceId = getDeviceIdentifier()
        
        lemonSqueezyService.validateLicense(key: key, deviceIdentifier: deviceId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success((let isValid, let limit, let usage)):
                    self.isValidLicense = isValid
                    self.activationLimit = limit
                    self.activationUsage = usage
                    if !isValid {
                        // Si la licencia ya no es válida, limpiamos
                        self.resetLicense()
                    }
                    
                case .failure(_):
                    // En caso de error de red, asumimos que la licencia sigue siendo válida
                    // para no bloquear al usuario por problemas de conexión
                    if self.licenseKey.isEmpty {
                        self.isValidLicense = false
                    }
                }
            }
        }
    }
    
    func getDeviceIdentifier() -> String {
        return userDefaults.string(forKey: deviceIdentifierKey) ?? "unknown"
    }
    
    func isAppUnlocked() -> Bool {
        return isValidLicense || isTrialActive
    }
    
    func resetLicense() {
        // Guardar temporalmente la clave y el identificador antes de eliminarlos
        let keyToDeactivate = licenseKey
        let deviceId = getDeviceIdentifier()
        
        // Si tenemos una clave válida, intentar desactivarla en el servidor
        if !keyToDeactivate.isEmpty {
            lemonSqueezyService.deactivateLicense(key: keyToDeactivate, deviceIdentifier: deviceId) { [weak self] success in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        print("Licencia desactivada exitosamente en el servidor")
                        // Limpiar el ID de instancia guardado
                        self.userDefaults.removeObject(forKey: self.instanceIdKey)
                    } else {
                        print("No se pudo desactivar la licencia en el servidor")
                    }
                    
                    // Limpiar los datos localmente independientemente del resultado
                    self.userDefaults.removeObject(forKey: self.licenseKeyKey)
                    self.licenseKey = ""
                    self.isValidLicense = false
                    self.lastErrorMessage = nil
                    
                    // Comprobar el estado del período de prueba
                    self.checkTrialStatus()
                }
            }
        } else {
            // Si no hay licencia activa, solo limpiar los datos locales
            userDefaults.removeObject(forKey: licenseKeyKey)
            licenseKey = ""
            isValidLicense = false
            lastErrorMessage = nil
            checkTrialStatus()
        }
    }
    
    func resetTrial() {
        userDefaults.removeObject(forKey: firstLaunchDateKey)
        checkTrialStatus()
    }
} 
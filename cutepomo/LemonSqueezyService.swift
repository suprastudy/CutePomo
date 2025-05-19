import Foundation

enum LicenseValidationError: Error {
    case invalidKey
    case networkError
    case invalidResponse
    case alreadyActivated
    case unknown
    
    var description: String {
        switch self {
        case .invalidKey:
            return "La clave de licencia no es válida"
        case .networkError:
            return "Error de conexión. Verifica tu conexión a internet"
        case .invalidResponse:
            return "Respuesta del servidor no válida"
        case .alreadyActivated:
            return "Esta licencia ya ha sido activada en otro dispositivo"
        case .unknown:
            return "Error desconocido. Inténtalo nuevamente"
        }
    }
}

// Las estructuras para decodificar la respuesta de la API de Lemon Squeezy
struct LemonSqueezyResponse: Codable {
    let valid: Bool?
    let error: String?
    let meta: Meta?
    let activated: Bool?
    let deactivated: Bool?
    let instance: Instance?
    let license_key: LicenseKey?
    
    struct Meta: Codable {
        let activationLimit: Int?
        let activationsCount: Int?
        let expiresAt: String?
        
        enum CodingKeys: String, CodingKey {
            case activationLimit = "activation_limit"
            case activationsCount = "activations_count"
            case expiresAt = "expires_at"
        }
    }
    
    struct Instance: Codable {
        let id: String
        let name: String
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case createdAt = "created_at"
        }
    }
    
    struct LicenseKey: Codable {
        let id: Int
        let status: String
        let key: String
        let activation_limit: Int
        let activation_usage: Int
        let created_at: String
        let expires_at: String?
    }
}

class LemonSqueezyService {
    static let shared = LemonSqueezyService()
    
    private let validateURL = "https://api.lemonsqueezy.com/v1/licenses/validate"
    private let activateURL = "https://api.lemonsqueezy.com/v1/licenses/activate"
    private let deactivateURL = "https://api.lemonsqueezy.com/v1/licenses/deactivate"
    
    // Tu API key de Lemon Squeezy (no se usa para estos endpoints)
    private let apiKey = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI5NGQ1OWNlZi1kYmI4LTRlYTUtYjE3OC1kMjU0MGZjZDY5MTkiLCJqdGkiOiI3NTg4ZmIyOTIyYTBlZjY2ZTk4OGY1OTVhNTdjZjQ3ZDk3OTE1ZGJlNmQ5YmEzZmNmMThiMjBiYjQ1OTE0ZDNlMjhjYzRhYzM1MTUzZWRmMCIsImlhdCI6MTc0NzA5MjczMi45OTg5MDMsIm5iZiI6MTc0NzA5MjczMi45OTg5MDYsImV4cCI6MjA2MjYyNTUzMi45NTY3NksInN1YiI6IjQ4Nzk2MTUiLCJzY29wZXMiOltdfQ.fDdTgVEnLUJQ0HnCmi35kP2FWbFKvH7_kdDtQwzZ2asCEHnrelHWWTySA8DObYUyIaIqtBupmKP2Ygb_5HEADUuA3Kgrkv2m-1X9QR_dSP1ESUF9gjNsYoIVjtiOAafq7uMMjorRhs_naX-rzW1Z8sVDsFL5n24EQZ9ZZBWIRYwD54PRFNbG4VzK0fiDHU9OhgUFp0arPQhU3FfyBD2CkAWTvizvu4UKBJlm8raPbcCYHQKzZvWRMJwYgnlUJB0lbYecZkHRNV1EgY5I30-drxiyxOl_b3x2h0o9mzfRB_CjhX7edh35dP3Sf9V156bwYqcrkVrwyn0eZOpH-zBsmePzROjdbXvzfVDiJgvOkDsUhYHGWq8BCTFNeSIuNo0bIhE41J5GBBLmEGz6Q2sBqrDMgW9lNEbwyBR3Na8GzjfL6OtnxSnq1JYoJ5mOnXzIgu7r8MVFCveLqPIg65hdCvqiLA2bjdTl9aTZ1dQzXpnqf0ckWZDj9VV6qkkSoitN"
    
    // Tu ID de producto
    private let productId = "513266"
    
    // Almacenar el ID de instancia después de la activación
    private var currentInstanceId: String?
    
    // Función para desactivar una licencia en Lemon Squeezy
    func deactivateLicense(key: String, deviceIdentifier: String, completion: @escaping (Bool) -> Void) {
        guard let instanceId = currentInstanceId else {
            print("No hay ID de instancia disponible para desactivar")
            completion(false)
            return
        }
        
        guard let url = URL(string: deactivateURL) else {
            print("URL de desactivación inválida")
            completion(false)
            return
        }
        
        let requestBody: [String: Any] = [
            "license_key": key,
            "instance_id": instanceId
        ]
        
        print("Desactivando licencia: \(key) con instance_id: \(instanceId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error de red en deactivateLicense: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código HTTP deactivateLicense: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("No se recibieron datos en deactivateLicense")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Respuesta deactivateLicense: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        if let error = response.error {
                            print("Error en la respuesta deactivateLicense: \(error)")
                            completion(false)
                            return
                        }
                        
                        let isDeactivated = response.deactivated ?? false
                        if isDeactivated {
                            self.currentInstanceId = nil // Limpiar el ID de instancia
                        }
                        print("La licencia fue desactivada: \(isDeactivated)")
                        completion(isDeactivated)
                    }
                } catch {
                    print("Error al decodificar la respuesta deactivateLicense: \(error)")
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("JSON deactivateLicense: \(json)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            task.resume()
        } catch {
            print("Error al crear la solicitud deactivateLicense: \(error)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    func validateLicense(key: String, deviceIdentifier: String, completion: @escaping (Result<(Bool, Int, Int), LicenseValidationError>) -> Void) {
        guard !key.isEmpty else {
            completion(.failure(.invalidKey))
            return
        }
        
        // Primero validamos la licencia
        validateLicenseOnly(key: key) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success((let isValid, let limit, let usage)):
                if isValid {
                    // Si ya tenemos un ID de instancia, significa que la licencia ya está activada en este dispositivo
                    if self.currentInstanceId != nil {
                        completion(.success((true, limit, usage)))
                        return
                    }
                    
                    // Si la licencia es válida y no está activada en este dispositivo, procedemos a activarla
                    self.activateLicense(key: key, deviceIdentifier: deviceIdentifier) { activateResult in
                        switch activateResult {
                        case .success(let activated):
                            // Volvemos a validar para obtener el nuevo conteo de activaciones
                            self.validateLicenseOnly(key: key) { finalResult in
                                switch finalResult {
                                case .success((_, let finalLimit, let finalUsage)):
                                    completion(.success((activated, finalLimit, finalUsage)))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.success((false, limit, usage)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func validateLicenseOnly(key: String, completion: @escaping (Result<(Bool, Int, Int), LicenseValidationError>) -> Void) {
        guard let url = URL(string: validateURL) else {
            completion(.failure(.networkError))
            return
        }
        
        let requestBody: [String: Any] = [
            "license_key": key
        ]
        
        print("Validando licencia: \(key)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error de red en validateLicenseOnly: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(.networkError))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código HTTP validateLicenseOnly: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("No se recibieron datos en validateLicenseOnly")
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Respuesta validateLicenseOnly: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        if let error = response.error {
                            print("Error en la respuesta validateLicenseOnly: \(error)")
                            completion(.failure(.invalidKey))
                            return
                        }
                        
                        guard let isValid = response.valid else {
                            print("No se pudo determinar si la licencia es válida")
                            completion(.failure(.invalidResponse))
                            return
                        }
                        
                        let activationLimit = response.license_key?.activation_limit ?? 0
                        let activationUsage = response.license_key?.activation_usage ?? 0
                        
                        print("La licencia es válida: \(isValid), Límite: \(activationLimit), Uso: \(activationUsage)")
                        completion(.success((isValid, activationLimit, activationUsage)))
                    }
                } catch {
                    print("Error al decodificar la respuesta validateLicenseOnly: \(error)")
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("JSON validateLicenseOnly: \(json)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                }
            }
            task.resume()
        } catch {
            print("Error al crear la solicitud validateLicenseOnly: \(error)")
            DispatchQueue.main.async {
                completion(.failure(.networkError))
            }
        }
    }
    
    private func activateLicense(key: String, deviceIdentifier: String, completion: @escaping (Result<Bool, LicenseValidationError>) -> Void) {
        guard let url = URL(string: activateURL) else {
            completion(.failure(.networkError))
            return
        }
        
        let requestBody: [String: Any] = [
            "license_key": key,
            "instance_name": deviceIdentifier
        ]
        
        print("Activando licencia: \(key) para dispositivo: \(deviceIdentifier)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error de red en activateLicense: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(.networkError))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Código HTTP activateLicense: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("No se recibieron datos en activateLicense")
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Respuesta activateLicense: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(LemonSqueezyResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        if let error = response.error {
                            print("Error en la respuesta activateLicense: \(error)")
                            if error.contains("already activated") {
                                completion(.failure(.alreadyActivated))
                            } else {
                                completion(.failure(.invalidKey))
                            }
                            return
                        }
                        
                        let isActivated = response.activated ?? false
                        if isActivated {
                            // Guardar el ID de instancia para usarlo en la desactivación
                            self.currentInstanceId = response.instance?.id
                            print("ID de instancia guardado: \(self.currentInstanceId ?? "nil")")
                        }
                        print("La licencia fue activada: \(isActivated)")
                        completion(.success(isActivated))
                    }
                } catch {
                    print("Error al decodificar la respuesta activateLicense: \(error)")
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("JSON activateLicense: \(json)")
                    }
                    
                    DispatchQueue.main.async {
                        completion(.failure(.invalidResponse))
                    }
                }
            }
            task.resume()
        } catch {
            print("Error al crear la solicitud activateLicense: \(error)")
            DispatchQueue.main.async {
                completion(.failure(.networkError))
            }
        }
    }
    
    // Métodos para gestionar el ID de instancia
    func getCurrentInstanceId() -> String? {
        return currentInstanceId
    }
    
    func restoreInstanceId(_ instanceId: String) {
        currentInstanceId = instanceId
    }
} 
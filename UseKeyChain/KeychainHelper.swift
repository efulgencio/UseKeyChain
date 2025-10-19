//
//  KeychainHelper.swift
//  UseKeyChain
//
//  Created by Eduardo Fulgencio on 19/10/2025.
//
//  💡 Este helper proporciona una interfaz sencilla y segura
//  para guardar, recuperar y eliminar datos sensibles en el Keychain.
//
//  🔐 El Keychain es el sistema de almacenamiento seguro de iOS.
//  Los datos se almacenan cifrados, gestionados por el sistema operativo,
//  y pueden persistir incluso tras cerrar la app o reiniciar el dispositivo.
//

import Foundation
import Security

/// Helper centralizado para operaciones con el Keychain.
final class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    // ============================================================
    // MARK: - 🔸 TIPOS DE ELEMENTOS EN EL KEYCHAIN
    // ============================================================
    //
    // kSecClass define el tipo de elemento que se va a almacenar:
    //
    // • kSecClassGenericPassword  → Contraseñas o datos genéricos (la más común)
    // • kSecClassInternetPassword → Credenciales de servicios de Internet
    // • kSecClassCertificate      → Certificados digitales
    // • kSecClassKey              → Claves criptográficas
    // • kSecClassIdentity         → Certificado + clave privada asociada
    //
    // En la mayoría de apps usaremos kSecClassGenericPassword.
    //
    
    // ============================================================
    // MARK: - 🧾 GUARDAR STRING O DATA
    // ============================================================
    
    /// Guarda datos binarios (`Data`) en el Keychain.
    /// Si ya existe un valor con la misma clave, lo reemplaza.
    func save(_ value: Data, for key: String) {
        // 1️⃣ Elimina cualquier entrada anterior con la misma clave
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: key] as CFDictionary
        SecItemDelete(query)
        
        // 2️⃣ Crea los atributos del nuevo ítem
        let attributes = [
            kSecClass: kSecClassGenericPassword,   // Tipo del ítem
            kSecAttrAccount: key,                  // Clave identificadora
            kSecValueData: value,                  // Valor binario
            // Define cuándo puede accederse al ítem:
            //  - kSecAttrAccessibleWhenUnlocked → Solo cuando el dispositivo está desbloqueado
            //  - kSecAttrAccessibleAfterFirstUnlock → Tras el primer desbloqueo (más flexible)
            //  - kSecAttrAccessibleAlways → Siempre accesible (menos seguro)
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary
        
        // 3️⃣ Inserta el nuevo elemento en el Keychain
        let status = SecItemAdd(attributes, nil)
        if status == errSecSuccess {
            print("✅ Valor guardado correctamente en Keychain.")
        } else {
            print("❌ Error al guardar en Keychain: \(status)")
        }
    }
    
    /// Guarda directamente un `String` en el Keychain.
    func save(_ string: String, for key: String) {
        if let data = string.data(using: .utf8) {
            save(data, for: key)
        }
    }
    
    // ============================================================
    // MARK: - 🔍 LEER DATOS
    // ============================================================
    
    /// Recupera datos (`Data`) desde el Keychain.
    func read(for key: String) -> Data? {
        // La consulta debe coincidir con los mismos atributos usados al guardar
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,            // Queremos obtener el valor almacenado
            kSecMatchLimit: kSecMatchLimitOne // Solo un resultado
        ] as CFDictionary
        
        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataRef)
        
        guard status == errSecSuccess else {
            print("⚠️ No se encontró valor para la clave '\(key)'.")
            return nil
        }
        return dataRef as? Data
    }
    
    /// Recupera un `String` almacenado en el Keychain.
    func readString(for key: String) -> String? {
        guard let data = read(for: key),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
    
    // ============================================================
    // MARK: - 🗑️ ELIMINAR DATOS
    // ============================================================
    
    /// Elimina un ítem del Keychain.
    func delete(for key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        if status == errSecSuccess {
            print("🗑️ Elemento eliminado correctamente del Keychain.")
        } else {
            print("⚠️ No se pudo eliminar o no existe (status: \(status)).")
        }
    }
    
    // ============================================================
    // MARK: - 🧩 GUARDAR OBJETOS CODABLE
    // ============================================================
    
    /// Guarda cualquier objeto que conforme a `Codable`.
    ///
    /// Convierte el objeto a JSON (Data) y lo almacena de forma segura.
    func save<T: Codable>(_ object: T, for key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            save(data, for: key)
        } catch {
            print("❌ Error al codificar objeto: \(error)")
        }
    }
    
    /// Recupera un objeto `Codable` almacenado.
    func readObject<T: Codable>(for key: String, type: T.Type) -> T? {
        guard let data = read(for: key) else { return nil }
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            print("❌ Error al decodificar objeto: \(error)")
            return nil
        }
    }
    
    // ============================================================
    // MARK: - 💡 CONSEJOS PRÁCTICOS
    // ============================================================
    //
    // ✅ Usa claves (`key`) únicas por tipo de dato o usuario.
    // ✅ No almacenes datos demasiado grandes (no está diseñado para eso).
    // ✅ El Keychain es persistente entre ejecuciones de la app.
    // ✅ Si quieres compartir datos con un Widget o extensión:
    //    usa `kSecAttrAccessGroup` (grupos de Keychain compartido).
    // ✅ Si el dispositivo tiene Face ID / Touch ID, puedes combinarlo
    //    con Keychain para autenticación biométrica.
    //
    // ============================================================
    // MARK: - 📘 EJEMPLOS DE USO
    // ============================================================
    //
    // // Guardar un String
    // KeychainHelper.shared.save("Eduardo", for: "nombreUsuario")
    //
    // // Leerlo
    // let nombre = KeychainHelper.shared.readString(for: "nombreUsuario")
    //
    // // Eliminarlo
    // KeychainHelper.shared.delete(for: "nombreUsuario")
    //
    // ------------------------------------------------------------
    //
    // // Guardar un objeto Codable
    // struct Usuario: Codable {
    //     let nombre: String
    //     let edad: Int
    // }
    //
    // let usuario = Usuario(nombre: "Eduardo", edad: 42)
    // KeychainHelper.shared.save(usuario, for: "usuarioGuardado")
    //
    // // Recuperar el objeto
    // if let usuarioRecuperado = KeychainHelper.shared.readObject(for: "usuarioGuardado", type: Usuario.self) {
    //     print(usuarioRecuperado.nombre, usuarioRecuperado.edad)
    // }
    //
    // ============================================================
}

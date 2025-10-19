//  CertificateManager.swift
//  UseKeyChain
//
//  Created by Eduardo Fulgencio on 19/10/2025.
//
//  🔐 Gestiona certificados digitales en el Keychain de iOS.
//  Permite guardar, importar (.cer / .p12), listar, eliminar y exportar certificados.
//

import Foundation
import Security

final class CertificateManager {
    
    static let shared = CertificateManager()
    private init() {}
    
    // ============================================================
    // MARK: - 💾 GUARDAR CERTIFICADO (.cer)
    // ============================================================
    func saveCertificate(named name: String) {
        guard let certURL = Bundle.main.url(forResource: name, withExtension: "cer"),
              let certData = try? Data(contentsOf: certURL) else {
            print("❌ No se encontró el certificado '\(name).cer' en el bundle.")
            return
        }
        
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            print("❌ No se pudo crear el objeto SecCertificate.")
            return
        }
        
        let query = [
            kSecClass: kSecClassCertificate,
            kSecValueRef: certificate
        ] as CFDictionary
        SecItemDelete(query)
        
        let addQuery = [
            kSecClass: kSecClassCertificate,
            kSecValueRef: certificate,
            kSecAttrLabel: name
        ] as CFDictionary
        
        let status = SecItemAdd(addQuery, nil)
        if status == errSecSuccess {
            print("✅ Certificado '\(name)' guardado correctamente en el Keychain.")
        } else {
            print("❌ Error al guardar el certificado (status \(status)).")
        }
    }
    
    // ============================================================
    // MARK: - 🔐 IMPORTAR CERTIFICADO (.p12 / .pfx)
    // ============================================================
    func importP12Certificate(named name: String, password: String) {
        guard let certURL = Bundle.main.url(forResource: name, withExtension: "p12"),
              let p12Data = try? Data(contentsOf: certURL) else {
            print("❌ No se encontró el archivo '\(name).p12'.")
            return
        }
        
        let options = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)
        
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let firstItem = array.first else {
            print("❌ Error al importar el archivo p12 (status \(status)).")
            return
        }
        
        guard let identityRef = firstItem[kSecImportItemIdentity as String],
              CFGetTypeID(identityRef as CFTypeRef) == SecIdentityGetTypeID() else {
            print("❌ No se encontró una identidad válida en el archivo .p12.")
            return
        }
        
        let identity = identityRef as! SecIdentity
        
        let addQuery = [
            kSecClass: kSecClassIdentity,
            kSecValueRef: identity,
            kSecAttrLabel: name
        ] as CFDictionary
        
        let addStatus = SecItemAdd(addQuery, nil)
        if addStatus == errSecSuccess {
            print("✅ Certificado p12 '\(name)' importado correctamente en el Keychain.")
        } else if addStatus == errSecDuplicateItem {
            print("⚠️ El certificado '\(name)' ya existe en el Keychain.")
        } else {
            print("⚠️ Error al añadir al Keychain (status \(addStatus)).")
        }
    }
    
    // ============================================================
    // MARK: - 📋 LISTAR CERTIFICADOS
    // ============================================================
    func listCertificates() {
        let query = [
            kSecClass: kSecClassCertificate,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitAll
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess else {
            print("⚠️ No se encontraron certificados (status \(status)).")
            return
        }
        
        if let certs = result as? [SecCertificate] {
            print("🔎 Certificados encontrados: \(certs.count)")
            for (index, cert) in certs.enumerated() {
                if let summary = SecCertificateCopySubjectSummary(cert) {
                    print("🧩 Certificado \(index + 1): \(summary)")
                }
            }
        } else {
            print("⚠️ No se pudieron listar certificados.")
        }
    }
    
    // ============================================================
    // MARK: - 🗑️ ELIMINAR CERTIFICADO
    // ============================================================
    func deleteCertificate(named name: String) {
        let query = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: name
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        if status == errSecSuccess {
            print("🗑️ Certificado '\(name)' eliminado del Keychain.")
        } else {
            print("⚠️ No se pudo eliminar (status \(status)).")
        }
    }
    
    // ============================================================
    // MARK: - 📤 EXPORTAR CERTIFICADO A DATA
    // ============================================================
    func exportCertificate(named name: String) -> Data? {
        let query = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: name,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess,
              let certRef = result,
              CFGetTypeID(certRef) == SecCertificateGetTypeID() else {
            print("⚠️ No se encontró el certificado '\(name)' para exportar.")
            return nil
        }
        
        let cert = certRef as! SecCertificate
        let certData = SecCertificateCopyData(cert) as Data
        print("📦 Certificado '\(name)' exportado correctamente (\(certData.count) bytes).")
        return certData
    }
    
    // ============================================================
    // MARK: - 💾 GUARDAR CERTIFICADO EXPORTADO EN ARCHIVO
    // ============================================================
    enum CertificateFileFormat {
        case cer
        case pem
    }
    
    /// Exporta un certificado desde el Keychain y lo guarda como archivo local (.cer o .pem)
    func saveExportedCertificateToFile(named name: String,
                                       format: CertificateFileFormat = .cer) {
        guard let certData = exportCertificate(named: name) else { return }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let fileURL: URL
        var dataToWrite: Data
        
        switch format {
        case .cer:
            fileURL = documentsURL.appendingPathComponent("\(name).cer")
            dataToWrite = certData
        case .pem:
            fileURL = documentsURL.appendingPathComponent("\(name).pem")
            let base64 = certData.base64EncodedString(options: [.lineLength64Characters])
            let pemString = """
            -----BEGIN CERTIFICATE-----
            \(base64)
            -----END CERTIFICATE-----
            """
            dataToWrite = pemString.data(using: .utf8)!
        }
        
        do {
            try dataToWrite.write(to: fileURL)
            print("✅ Certificado guardado en: \(fileURL.path)")
        } catch {
            print("❌ Error al escribir el archivo: \(error.localizedDescription)")
        }
    }
    
    // ============================================================
    // MARK: - 💡 EJEMPLOS DE USO
    // ============================================================
    //
    // // 1️⃣ Guardar un certificado público (.cer)
    // CertificateManager.shared.saveCertificate(named: "myCert")
    //
    // // 2️⃣ Importar un certificado con clave privada (.p12)
    // CertificateManager.shared.importP12Certificate(named: "myCertPrivate", password: "1234")
    //
    // // 3️⃣ Listar certificados guardados
    // CertificateManager.shared.listCertificates()
    //
    // // 4️⃣ Exportar certificado como Data o Base64
    // if let certData = CertificateManager.shared.exportCertificate(named: "myCert") {
    //     let base64 = certData.base64EncodedString()
    //     print("🔐 Certificado Base64:\n\(base64)")
    // }
    //
    // // 5️⃣ Guardar el certificado exportado como archivo .cer o .pem
    // CertificateManager.shared.saveExportedCertificateToFile(named: "myCert", format: .pem)
    //
    // // 6️⃣ Eliminar un certificado
    // CertificateManager.shared.deleteCertificate(named: "myCert")
    //
    // ============================================================
    // MARK: - ⚠️ NOTAS
    // ============================================================
    //
    // • Los archivos se guardan en el sandbox de la app:
    //   ~/Library/Containers/.../Documents/
    //   Puedes acceder desde el simulador o app Archivos.
    //
    // • .cer → formato binario DER.
    // • .pem → formato texto Base64 con cabeceras.
    // • Ideal para inspeccionar el certificado con herramientas externas (OpenSSL).
    //
    // ============================================================
}


/*

 override func viewDidLoad() {
     super.viewDidLoad()
     
     // 1. Guardar un certificado
     CertificateManager.shared.saveCertificate(named: "myCert")

     // 2. Exportarlo y convertirlo a Base64
     if let certData = CertificateManager.shared.exportCertificate(named: "myCert") {
         let base64 = certData.base64EncodedString()
         print("🔐 Certificado en Base64:\n\(base64)")
     }

     // 3. Listar los certificados guardados
     CertificateManager.shared.listCertificates()
 }

 override func viewDidLoad() {
     super.viewDidLoad()
     
     // Guardar un certificado desde el bundle
     CertificateManager.shared.saveCertificate(named: "myCert")
     
     // Exportarlo a PEM y guardarlo como archivo
     CertificateManager.shared.saveExportedCertificateToFile(named: "myCert", format: .pem)
 }

 El archivo se guarda en
 /Documents/myCert.pem
 y podrás verlo en el simulador (o en “Archivos” en un dispositivo real).
 
 */

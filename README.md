# 🔐 Guía de Tipos de Keychain en iOS

Esta guía explica los principales tipos (`kSecClass`) del **Keychain** en iOS y macOS, sus usos, atributos y ejemplos de implementación.

---

## 📘 ¿Qué es el Keychain?

El **Keychain** es el sistema de almacenamiento seguro de Apple.  
Permite guardar información sensible (contraseñas, tokens, certificados, claves privadas, etc.) de forma **cifrada y persistente**.

Cada elemento guardado pertenece a una **clase (`kSecClass`)** que define el tipo de dato y sus atributos válidos.

---

## 🔑 Tipos principales de `kSecClass`

| Tipo | Qué almacena | Ejemplo de uso |
|------|---------------|----------------|
| `kSecClassGenericPassword` | Contraseñas o datos genéricos | Tokens, credenciales locales |
| `kSecClassInternetPassword` | Contraseñas de servicios de red | Login de API o FTP |
| `kSecClassCertificate` | Certificados X.509 públicos | Guardar `.cer`, `.der` |
| `kSecClassKey` | Claves criptográficas | RSA, EC, AES |
| `kSecClassIdentity` | Certificado + clave privada | Importar `.p12`, `.pfx` |

---

## 1️⃣ `kSecClassGenericPassword`
**Contraseñas o datos genéricos (la más común).**

Usada para guardar información sensible no asociada a servidores (tokens, credenciales locales).

```swift
let query = [
    kSecClass: kSecClassGenericPassword,
    kSecAttrAccount: "userEmail",
    kSecValueData: "eduardo@example.com".data(using: .utf8)!
] as CFDictionary
SecItemAdd(query, nil)
```

---

## 2️⃣ `kSecClassInternetPassword`
**Credenciales de servicios de Internet.**

Permite asociar usuario, servidor, protocolo y puerto a una contraseña de red.

```swift
let query = [
    kSecClass: kSecClassInternetPassword,
    kSecAttrAccount: "user123",
    kSecAttrServer: "api.misitio.com",
    kSecAttrProtocol: kSecAttrProtocolHTTPS,
    kSecValueData: "secreto123".data(using: .utf8)!
] as CFDictionary
SecItemAdd(query, nil)
```

---

## 3️⃣ `kSecClassCertificate`
**Certificados digitales (.cer, .der).**

Representa un certificado X.509 (solo parte pública).  
Usado en validaciones TLS, firmas o identidades.

```swift
let certData = try! Data(contentsOf: Bundle.main.url(forResource: "myCert", withExtension: "cer")!)
let certificate = SecCertificateCreateWithData(nil, certData as CFData)!

let query = [
    kSecClass: kSecClassCertificate,
    kSecValueRef: certificate,
    kSecAttrLabel: "myCert"
] as CFDictionary
SecItemAdd(query, nil)
```

---

## 4️⃣ `kSecClassKey`
**Claves criptográficas (pública o privada).**

Permite guardar claves generadas o importadas para cifrar, firmar o verificar datos.

```swift
var attributes: [String: Any] = [
    kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
    kSecAttrKeySizeInBits as String: 2048,
    kSecAttrIsPermanent as String: true,
    kSecAttrApplicationTag as String: "com.myapp.privatekey"
]
var error: Unmanaged<CFError>?
if let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) {
    print("✅ Clave privada generada y guardada en Keychain.")
}
```

---

## 5️⃣ `kSecClassIdentity`
**Certificado + clave privada (identidad completa).**

Asocia el certificado público con su clave privada.  
Normalmente se importa desde archivos `.p12` o `.pfx`.

```swift
let options = [kSecImportExportPassphrase as String: "1234"]
var items: CFArray?
SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)

let identity = (items as! [[String: Any]]).first![kSecImportItemIdentity as String] as! SecIdentity

let query = [
    kSecClass: kSecClassIdentity,
    kSecValueRef: identity,
    kSecAttrLabel: "miIdentidad"
] as CFDictionary
SecItemAdd(query, nil)
```

---

## ⚙️ Consejos prácticos

- En el **90% de los casos**, usarás `kSecClassGenericPassword`.
- Cada tipo de `kSecClass` acepta distintos atributos (`kSecAttr...`).
- Usar un atributo incorrecto puede devolver `errSecParam`.
- Los datos del Keychain están cifrados por el sistema y persisten entre reinicios.
- Puedes compartir el Keychain entre apps usando `kSecAttrAccessGroup`.

---

## 📘 Referencias oficiales

- [Apple Developer – Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [SecItem – Keychain Items API](https://developer.apple.com/documentation/security/keychain_services/keychain_items)

---

✍️ **Autor:** Eduardo Fulgencio  
📅 **Actualizado:** Octubre 2025  
📄 **Licencia:** MIT

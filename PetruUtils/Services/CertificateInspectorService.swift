import Foundation
import Security

/// Service for inspecting X.509 certificates
struct CertificateInspectorService {

    enum CertificateError: LocalizedError {
        case invalidFormat
        case decodingFailed
        case noCertificateFound
        case invalidPEM
        case invalidDER

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid certificate format. Please provide a valid PEM or DER encoded certificate."
            case .decodingFailed:
                return "Failed to decode certificate. The certificate data may be corrupted."
            case .noCertificateFound:
                return "No certificate found in the provided input."
            case .invalidPEM:
                return "Invalid PEM format. Expected certificate to be enclosed in BEGIN/END CERTIFICATE markers."
            case .invalidDER:
                return "Invalid DER format. The binary data does not represent a valid certificate."
            }
        }
    }

    /// Information extracted from a certificate
    struct CertificateInfo: Codable {
        let version: Int
        let serialNumber: String
        let subject: [String: String]
        let issuer: [String: String]
        let validFrom: Date
        let validTo: Date
        let isExpired: Bool
        let daysUntilExpiration: Int?
        let publicKeyAlgorithm: String
        let publicKeySize: Int?
        let signatureAlgorithm: String
        let subjectAlternativeNames: [String]
        let keyUsage: [String]
        let extendedKeyUsage: [String]
        let isCA: Bool
        let isSelfSigned: Bool
        let sha1Fingerprint: String
        let sha256Fingerprint: String

        var subjectCommonName: String? {
            subject["CN"] ?? subject["2.5.4.3"]
        }

        var issuerCommonName: String? {
            issuer["CN"] ?? issuer["2.5.4.3"]
        }

        var formattedSubject: String {
            formatDN(subject)
        }

        var formattedIssuer: String {
            formatDN(issuer)
        }

        private func formatDN(_ components: [String: String]) -> String {
            let order = ["CN", "OU", "O", "L", "ST", "C"]
            var parts: [String] = []

            for key in order {
                if let value = components[key] {
                    parts.append("\(key)=\(value)")
                }
            }

            // Add any remaining components
            for (key, value) in components where !order.contains(key) {
                parts.append("\(key)=\(value)")
            }

            return parts.joined(separator: ", ")
        }
    }

    /// Parses a certificate from PEM or DER format
    /// - Parameter input: Certificate string (PEM) or base64 (DER)
    /// - Returns: Certificate information
    func parseCertificate(_ input: String) throws -> CertificateInfo {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw CertificateError.noCertificateFound
        }

        // Try PEM first, then DER
        let certData: Data
        if trimmed.contains("BEGIN CERTIFICATE") {
            certData = try parsePEM(trimmed)
        } else {
            // Try as base64-encoded DER
            certData = try parseDER(trimmed)
        }

        // Create SecCertificate
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw CertificateError.decodingFailed
        }

        return try extractCertificateInfo(from: certificate)
    }

    /// Parses PEM format certificate
    private func parsePEM(_ pem: String) throws -> Data {
        // Extract content between BEGIN and END markers
        let pattern = "-----BEGIN CERTIFICATE-----([\\s\\S]+?)-----END CERTIFICATE-----"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: pem, range: NSRange(pem.startIndex..., in: pem)),
              match.numberOfRanges > 1 else {
            throw CertificateError.invalidPEM
        }

        let base64Range = match.range(at: 1)
        let base64String = (pem as NSString).substring(with: base64Range)
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)

        guard let data = Data(base64Encoded: base64String) else {
            throw CertificateError.invalidPEM
        }

        return data
    }

    /// Parses DER format certificate
    private func parseDER(_ base64: String) throws -> Data {
        let cleaned = base64.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)

        guard let data = Data(base64Encoded: cleaned) else {
            throw CertificateError.invalidDER
        }

        return data
    }

    /// Extracts information from a SecCertificate
    private func extractCertificateInfo(from certificate: SecCertificate) throws -> CertificateInfo {
        // Get certificate summary (this gives us basic info)
        let summary = SecCertificateCopySubjectSummary(certificate) as String? ?? "Unknown"

        // Get certificate values
        var error: Unmanaged<CFError>?
        guard let values = SecCertificateCopyValues(certificate, nil, &error) as? [String: Any] else {
            throw CertificateError.decodingFailed
        }

        // Extract subject and issuer
        let subject = extractDistinguishedName(from: values, key: kSecOIDX509V1SubjectName as String)
        let issuer = extractDistinguishedName(from: values, key: kSecOIDX509V1IssuerName as String)

        // Extract serial number
        let serialNumber = extractSerialNumber(from: values)

        // Extract validity dates
        let (validFrom, validTo) = extractValidityDates(from: values)

        // Calculate expiration
        let now = Date()
        let isExpired = validTo < now
        let daysUntilExpiration = isExpired ? nil : Calendar.current.dateComponents([.day], from: now, to: validTo).day

        // Extract public key info
        let (publicKeyAlg, publicKeySize) = extractPublicKeyInfo(from: certificate)

        // Extract signature algorithm
        let signatureAlgorithm = extractSignatureAlgorithm(from: values)

        // Extract extensions
        let subjectAltNames = extractSubjectAlternativeNames(from: values)
        let keyUsage = extractKeyUsage(from: values)
        let extendedKeyUsage = extractExtendedKeyUsage(from: values)
        let isCA = extractBasicConstraints(from: values)

        // Check if self-signed
        let isSelfSigned = subject == issuer

        // Calculate fingerprints
        let certData = SecCertificateCopyData(certificate) as Data
        let sha1 = calculateSHA1(data: certData)
        let sha256 = calculateSHA256(data: certData)

        return CertificateInfo(
            version: 3, // Most certs are v3
            serialNumber: serialNumber,
            subject: subject,
            issuer: issuer,
            validFrom: validFrom,
            validTo: validTo,
            isExpired: isExpired,
            daysUntilExpiration: daysUntilExpiration,
            publicKeyAlgorithm: publicKeyAlg,
            publicKeySize: publicKeySize,
            signatureAlgorithm: signatureAlgorithm,
            subjectAlternativeNames: subjectAltNames,
            keyUsage: keyUsage,
            extendedKeyUsage: extendedKeyUsage,
            isCA: isCA,
            isSelfSigned: isSelfSigned,
            sha1Fingerprint: sha1,
            sha256Fingerprint: sha256
        )
    }

    private func extractDistinguishedName(from values: [String: Any], key: String) -> [String: String] {
        guard let value = values[key] as? [String: Any],
              let valueArray = value[kSecPropertyKeyValue as String] as? [[String: Any]] else {
            return [:]
        }

        var result: [String: String] = [:]
        for item in valueArray {
            if let label = item[kSecPropertyKeyLabel as String] as? String,
               let value = item[kSecPropertyKeyValue as String] as? String {
                result[label] = value
            }
        }

        return result
    }

    private func extractSerialNumber(from values: [String: Any]) -> String {
        guard let value = values[kSecOIDX509V1SerialNumber as String] as? [String: Any],
              let data = value[kSecPropertyKeyValue as String] as? Data else {
            return "Unknown"
        }

        return data.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func extractValidityDates(from values: [String: Any]) -> (Date, Date) {
        let formatter = ISO8601DateFormatter()

        var validFrom = Date()
        var validTo = Date()

        if let notBeforeValue = values[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
           let notBeforeNumber = notBeforeValue[kSecPropertyKeyValue as String] as? NSNumber {
            validFrom = Date(timeIntervalSinceReferenceDate: notBeforeNumber.doubleValue)
        }

        if let notAfterValue = values[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
           let notAfterNumber = notAfterValue[kSecPropertyKeyValue as String] as? NSNumber {
            validTo = Date(timeIntervalSinceReferenceDate: notAfterNumber.doubleValue)
        }

        return (validFrom, validTo)
    }

    private func extractPublicKeyInfo(from certificate: SecCertificate) -> (String, Int?) {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return ("Unknown", nil)
        }

        let attributes = SecKeyCopyAttributes(publicKey) as? [String: Any]
        let keyType = attributes?[kSecAttrKeyType as String] as? String ?? "Unknown"
        let keySize = attributes?[kSecAttrKeySizeInBits as String] as? Int

        let algorithm: String
        if keyType == kSecAttrKeyTypeRSA as String {
            algorithm = "RSA"
        } else if keyType == kSecAttrKeyTypeECSECPrimeRandom as String {
            algorithm = "ECDSA"
        } else {
            algorithm = keyType
        }

        return (algorithm, keySize)
    }

    private func extractSignatureAlgorithm(from values: [String: Any]) -> String {
        guard let value = values[kSecOIDX509V1SignatureAlgorithm as String] as? [String: Any],
              let algValue = value[kSecPropertyKeyValue as String] as? [String: Any],
              let algorithm = algValue[kSecPropertyKeyValue as String] as? String else {
            return "Unknown"
        }

        return algorithm
    }

    private func extractSubjectAlternativeNames(from values: [String: Any]) -> [String] {
        guard let value = values[kSecOIDSubjectAltName as String] as? [String: Any],
              let valueArray = value[kSecPropertyKeyValue as String] as? [[String: Any]] else {
            return []
        }

        var names: [String] = []
        for item in valueArray {
            if let label = item[kSecPropertyKeyLabel as String] as? String,
               let value = item[kSecPropertyKeyValue as String] as? String {
                names.append("\(label): \(value)")
            }
        }

        return names
    }

    private func extractKeyUsage(from values: [String: Any]) -> [String] {
        // Simplified - would need more complex parsing in production
        return []
    }

    private func extractExtendedKeyUsage(from values: [String: Any]) -> [String] {
        guard let value = values[kSecOIDExtendedKeyUsage as String] as? [String: Any],
              let valueArray = value[kSecPropertyKeyValue as String] as? [[String: Any]] else {
            return []
        }

        var usages: [String] = []
        for item in valueArray {
            if let usage = item[kSecPropertyKeyValue as String] as? String {
                usages.append(usage)
            }
        }

        return usages
    }

    private func extractBasicConstraints(from values: [String: Any]) -> Bool {
        guard let value = values[kSecOIDBasicConstraints as String] as? [String: Any],
              let valueArray = value[kSecPropertyKeyValue as String] as? [[String: Any]] else {
            return false
        }

        for item in valueArray {
            if let label = item[kSecPropertyKeyLabel as String] as? String,
               label == "Certificate Authority",
               let isCA = item[kSecPropertyKeyValue as String] as? String {
                return isCA.lowercased() == "yes" || isCA == "1"
            }
        }

        return false
    }

    private func calculateSHA1(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func calculateSHA256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    /// Exports certificate info as JSON
    func exportAsJSON(_ info: CertificateInfo) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(info)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// CommonCrypto imports
import CommonCrypto

import Foundation
import Security

struct RandomStringService {
    enum CharacterSet {
        case lowercase
        case uppercase
        case numbers
        case symbols
        case custom(String)
        
        var characters: String {
            switch self {
            case .lowercase:
                return "abcdefghijklmnopqrstuvwxyz"
            case .uppercase:
                return "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            case .numbers:
                return "0123456789"
            case .symbols:
                return "!@#$%^&*()_+-=[]{}|;:,.<>?"
            case .custom(let chars):
                return chars
            }
        }
    }
    
    enum RandomStringError: LocalizedError {
        case invalidLength
        case noCharacterSetsSelected
        case cryptoError
        
        var errorDescription: String? {
            switch self {
            case .invalidLength:
                return "Length must be between 1 and 10000"
            case .noCharacterSetsSelected:
                return "At least one character set must be selected"
            case .cryptoError:
                return "Failed to generate cryptographically secure random data"
            }
        }
    }
    
    /// Generate a cryptographically secure random string
    func generate(
        length: Int,
        characterSets: [CharacterSet],
        excludeAmbiguous: Bool = false
    ) throws -> String {
        guard length > 0 && length <= 10000 else {
            throw RandomStringError.invalidLength
        }
        
        guard !characterSets.isEmpty else {
            throw RandomStringError.noCharacterSetsSelected
        }
        
        // Combine selected character sets
        var availableChars = characterSets.map { $0.characters }.joined()
        
        // Remove ambiguous characters if requested
        if excludeAmbiguous {
            let ambiguous = "0O1lI"
            availableChars = String(availableChars.filter { !ambiguous.contains($0) })
        }
        
        guard !availableChars.isEmpty else {
            throw RandomStringError.noCharacterSetsSelected
        }
        
        // Generate cryptographically secure random string
        let availableArray = Array(availableChars)
        var result = ""
        
        for _ in 0..<length {
            guard let randomChar = secureRandomElement(from: availableArray) else {
                throw RandomStringError.cryptoError
            }
            result.append(randomChar)
        }
        
        return result
    }
    
    /// Generate multiple random strings
    func generateMultiple(
        count: Int,
        length: Int,
        characterSets: [CharacterSet],
        excludeAmbiguous: Bool = false
    ) throws -> [String] {
        guard count > 0 && count <= 100 else {
            throw RandomStringError.invalidLength
        }
        
        var results: [String] = []
        for _ in 0..<count {
            let string = try generate(length: length, characterSets: characterSets, excludeAmbiguous: excludeAmbiguous)
            results.append(string)
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    /// Get a cryptographically secure random element from an array
    private func secureRandomElement<T>(from array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        
        var randomIndex: UInt32 = 0
        let result = SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt32>.size, &randomIndex)
        
        guard result == errSecSuccess else {
            return nil
        }
        
        let index = Int(randomIndex) % array.count
        return array[index]
    }
}

import Foundation

/// Service for IP address utilities including CIDR/subnet calculations
struct IPUtilitiesService {

    // MARK: - Error Types

    enum IPError: LocalizedError {
        case invalidIPv4Address
        case invalidIPv6Address
        case invalidCIDRNotation
        case invalidSubnetMask
        case prefixLengthOutOfRange
        case emptyInput

        var errorDescription: String? {
            switch self {
            case .invalidIPv4Address:
                return "Invalid IPv4 address. Must be four octets (0-255) separated by dots."
            case .invalidIPv6Address:
                return "Invalid IPv6 address format."
            case .invalidCIDRNotation:
                return "Invalid CIDR notation. Use format: IP/prefix (e.g., 192.168.1.0/24)"
            case .invalidSubnetMask:
                return "Invalid subnet mask. Must be a valid contiguous mask."
            case .prefixLengthOutOfRange:
                return "Prefix length out of range (0-32 for IPv4, 0-128 for IPv6)."
            case .emptyInput:
                return "Input cannot be empty."
            }
        }
    }

    // MARK: - IPv4 Address Representation

    struct IPv4Address: Equatable {
        let octets: [UInt8]

        var stringValue: String {
            octets.map { String($0) }.joined(separator: ".")
        }

        var binaryString: String {
            octets.map { String($0, radix: 2).padLeft(toLength: 8, withPad: "0") }.joined(separator: ".")
        }

        var hexString: String {
            octets.map { String(format: "%02X", $0) }.joined(separator: ":")
        }

        var intValue: UInt32 {
            octets.enumerated().reduce(0) { result, item in
                result | (UInt32(item.element) << (24 - item.offset * 8))
            }
        }

        init(octets: [UInt8]) {
            self.octets = octets
        }

        init(intValue: UInt32) {
            var octets: [UInt8] = []
            for i in (0..<4).reversed() {
                octets.append(UInt8((intValue >> (i * 8)) & 0xFF))
            }
            self.octets = octets
        }
    }

    // MARK: - Subnet Calculation Result

    struct SubnetInfo: Equatable {
        let network: IPv4Address
        let broadcast: IPv4Address
        let firstHost: IPv4Address
        let lastHost: IPv4Address
        let subnetMask: IPv4Address
        let wildcardMask: IPv4Address
        let prefixLength: Int
        let totalHosts: UInt32
        let usableHosts: UInt32
        let ipClass: String
        let isPrivate: Bool
    }

    // MARK: - Parsing

    /// Parse an IPv4 address string
    func parseIPv4(_ input: String) throws -> IPv4Address {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            throw IPError.emptyInput
        }

        let parts = trimmed.split(separator: ".")

        guard parts.count == 4 else {
            throw IPError.invalidIPv4Address
        }

        var octets: [UInt8] = []
        for part in parts {
            guard let value = UInt8(part), String(value) == String(part) else {
                throw IPError.invalidIPv4Address
            }
            octets.append(value)
        }

        return IPv4Address(octets: octets)
    }

    /// Parse CIDR notation (e.g., "192.168.1.0/24")
    func parseCIDR(_ input: String) throws -> (ip: IPv4Address, prefixLength: Int) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            throw IPError.emptyInput
        }

        let parts = trimmed.split(separator: "/")

        guard parts.count == 2 else {
            throw IPError.invalidCIDRNotation
        }

        let ip = try parseIPv4(String(parts[0]))

        guard let prefix = Int(parts[1]), prefix >= 0, prefix <= 32 else {
            throw IPError.prefixLengthOutOfRange
        }

        return (ip, prefix)
    }

    /// Parse subnet mask and return prefix length
    func subnetMaskToPrefixLength(_ mask: IPv4Address) throws -> Int {
        let intValue = mask.intValue

        // Check if it's a valid contiguous mask
        var foundZero = false
        var prefixLength = 0

        for i in (0..<32).reversed() {
            let bit = (intValue >> i) & 1
            if bit == 1 {
                if foundZero {
                    throw IPError.invalidSubnetMask
                }
                prefixLength += 1
            } else {
                foundZero = true
            }
        }

        return prefixLength
    }

    // MARK: - Subnet Calculations

    /// Calculate subnet information from IP and prefix length
    func calculateSubnet(ip: IPv4Address, prefixLength: Int) throws -> SubnetInfo {
        guard prefixLength >= 0 && prefixLength <= 32 else {
            throw IPError.prefixLengthOutOfRange
        }

        // Calculate subnet mask
        let maskInt: UInt32 = prefixLength == 0 ? 0 : (0xFFFFFFFF << (32 - prefixLength))
        let subnetMask = IPv4Address(intValue: maskInt)

        // Calculate wildcard mask (inverse of subnet mask)
        let wildcardInt = ~maskInt
        let wildcardMask = IPv4Address(intValue: wildcardInt)

        // Calculate network address (IP AND subnet mask)
        let networkInt = ip.intValue & maskInt
        let network = IPv4Address(intValue: networkInt)

        // Calculate broadcast address (network OR wildcard)
        let broadcastInt = networkInt | wildcardInt
        let broadcast = IPv4Address(intValue: broadcastInt)

        // Calculate first and last usable hosts
        let firstHostInt = prefixLength == 32 ? networkInt : networkInt + 1
        let lastHostInt = prefixLength >= 31 ? broadcastInt : broadcastInt - 1
        let firstHost = IPv4Address(intValue: firstHostInt)
        let lastHost = IPv4Address(intValue: lastHostInt)

        // Calculate total and usable hosts
        let totalHosts: UInt32 = prefixLength == 32 ? 1 : (1 << (32 - prefixLength))
        let usableHosts: UInt32
        if prefixLength == 32 {
            usableHosts = 1
        } else if prefixLength == 31 {
            usableHosts = 2 // Point-to-point link
        } else {
            usableHosts = totalHosts > 2 ? totalHosts - 2 : 0
        }

        // Determine IP class
        let ipClass = determineIPClass(ip)

        // Check if private
        let isPrivate = isPrivateIP(ip)

        return SubnetInfo(
            network: network,
            broadcast: broadcast,
            firstHost: firstHost,
            lastHost: lastHost,
            subnetMask: subnetMask,
            wildcardMask: wildcardMask,
            prefixLength: prefixLength,
            totalHosts: totalHosts,
            usableHosts: usableHosts,
            ipClass: ipClass,
            isPrivate: isPrivate
        )
    }

    /// Calculate subnet from CIDR notation
    func calculateSubnetFromCIDR(_ cidr: String) throws -> SubnetInfo {
        let (ip, prefixLength) = try parseCIDR(cidr)
        return try calculateSubnet(ip: ip, prefixLength: prefixLength)
    }

    /// Calculate subnet from IP and subnet mask
    func calculateSubnetFromMask(ip: IPv4Address, mask: IPv4Address) throws -> SubnetInfo {
        let prefixLength = try subnetMaskToPrefixLength(mask)
        return try calculateSubnet(ip: ip, prefixLength: prefixLength)
    }

    // MARK: - IP Classification

    /// Determine the class of an IP address
    func determineIPClass(_ ip: IPv4Address) -> String {
        let firstOctet = ip.octets[0]

        if firstOctet < 128 {
            return "A"
        } else if firstOctet < 192 {
            return "B"
        } else if firstOctet < 224 {
            return "C"
        } else if firstOctet < 240 {
            return "D (Multicast)"
        } else {
            return "E (Reserved)"
        }
    }

    /// Check if an IP is private
    func isPrivateIP(_ ip: IPv4Address) -> Bool {
        let first = ip.octets[0]
        let second = ip.octets[1]

        // 10.0.0.0/8
        if first == 10 {
            return true
        }

        // 172.16.0.0/12
        if first == 172 && second >= 16 && second <= 31 {
            return true
        }

        // 192.168.0.0/16
        if first == 192 && second == 168 {
            return true
        }

        // Loopback 127.0.0.0/8
        if first == 127 {
            return true
        }

        // Link-local 169.254.0.0/16
        if first == 169 && second == 254 {
            return true
        }

        return false
    }

    /// Check if an IP is in a given subnet
    func isIPInSubnet(ip: IPv4Address, network: IPv4Address, prefixLength: Int) -> Bool {
        guard prefixLength >= 0 && prefixLength <= 32 else {
            return false
        }

        let maskInt: UInt32 = prefixLength == 0 ? 0 : (0xFFFFFFFF << (32 - prefixLength))

        return (ip.intValue & maskInt) == (network.intValue & maskInt)
    }

    // MARK: - Subnet Division

    /// Divide a subnet into smaller subnets
    func divideSubnet(network: IPv4Address, prefixLength: Int, newPrefixLength: Int) throws -> [SubnetInfo] {
        guard prefixLength >= 0 && prefixLength <= 32 else {
            throw IPError.prefixLengthOutOfRange
        }

        guard newPrefixLength > prefixLength && newPrefixLength <= 32 else {
            throw IPError.prefixLengthOutOfRange
        }

        let numSubnets = 1 << (newPrefixLength - prefixLength)
        let subnetSize: UInt32 = 1 << (32 - newPrefixLength)

        var subnets: [SubnetInfo] = []
        var currentNetworkInt = network.intValue

        for _ in 0..<numSubnets {
            let subnetIP = IPv4Address(intValue: currentNetworkInt)
            let info = try calculateSubnet(ip: subnetIP, prefixLength: newPrefixLength)
            subnets.append(info)
            currentNetworkInt += subnetSize
        }

        return subnets
    }

    // MARK: - IPv4 Validation

    /// Validate an IPv4 address string
    func isValidIPv4(_ input: String) -> Bool {
        do {
            _ = try parseIPv4(input)
            return true
        } catch {
            return false
        }
    }

    /// Validate a CIDR notation string
    func isValidCIDR(_ input: String) -> Bool {
        do {
            _ = try parseCIDR(input)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Common Subnet Masks

    static let commonSubnetMasks: [(name: String, prefix: Int, mask: String, hosts: String)] = [
        ("/8 (Class A)", 8, "255.0.0.0", "16,777,214"),
        ("/16 (Class B)", 16, "255.255.0.0", "65,534"),
        ("/24 (Class C)", 24, "255.255.255.0", "254"),
        ("/25", 25, "255.255.255.128", "126"),
        ("/26", 26, "255.255.255.192", "62"),
        ("/27", 27, "255.255.255.224", "30"),
        ("/28", 28, "255.255.255.240", "14"),
        ("/29", 29, "255.255.255.248", "6"),
        ("/30 (Point-to-point)", 30, "255.255.255.252", "2"),
        ("/31 (RFC 3021)", 31, "255.255.255.254", "2"),
        ("/32 (Host)", 32, "255.255.255.255", "1")
    ]
}

// MARK: - String Extension

private extension String {
    func padLeft(toLength length: Int, withPad pad: String) -> String {
        let needed = length - count
        if needed <= 0 {
            return self
        }
        return String(repeating: pad, count: needed) + self
    }
}

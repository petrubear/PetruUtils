import Testing
import Foundation
@testable import PetruUtils

@Suite("IP Utilities Service Tests")
struct IPUtilitiesServiceTests {
    let service = IPUtilitiesService()

    // MARK: - IPv4 Parsing Tests

    @Test("Parse valid IPv4 address")
    func testParseValidIPv4() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        #expect(ip.octets == [192, 168, 1, 1])
        #expect(ip.stringValue == "192.168.1.1")
    }

    @Test("Parse IPv4 with zeros")
    func testParseIPv4WithZeros() throws {
        let ip = try service.parseIPv4("0.0.0.0")
        #expect(ip.octets == [0, 0, 0, 0])
    }

    @Test("Parse IPv4 max values")
    func testParseIPv4MaxValues() throws {
        let ip = try service.parseIPv4("255.255.255.255")
        #expect(ip.octets == [255, 255, 255, 255])
    }

    @Test("Parse IPv4 with whitespace")
    func testParseIPv4WithWhitespace() throws {
        let ip = try service.parseIPv4("  10.0.0.1  ")
        #expect(ip.octets == [10, 0, 0, 1])
    }

    @Test("Invalid IPv4 - too few octets")
    func testInvalidIPv4TooFewOctets() {
        #expect(throws: IPUtilitiesService.IPError.invalidIPv4Address) {
            _ = try service.parseIPv4("192.168.1")
        }
    }

    @Test("Invalid IPv4 - too many octets")
    func testInvalidIPv4TooManyOctets() {
        #expect(throws: IPUtilitiesService.IPError.invalidIPv4Address) {
            _ = try service.parseIPv4("192.168.1.1.1")
        }
    }

    @Test("Invalid IPv4 - octet out of range")
    func testInvalidIPv4OctetOutOfRange() {
        #expect(throws: IPUtilitiesService.IPError.invalidIPv4Address) {
            _ = try service.parseIPv4("192.168.1.256")
        }
    }

    @Test("Invalid IPv4 - negative octet")
    func testInvalidIPv4NegativeOctet() {
        #expect(throws: IPUtilitiesService.IPError.invalidIPv4Address) {
            _ = try service.parseIPv4("192.168.-1.1")
        }
    }

    @Test("Invalid IPv4 - empty input")
    func testInvalidIPv4Empty() {
        #expect(throws: IPUtilitiesService.IPError.emptyInput) {
            _ = try service.parseIPv4("")
        }
    }

    // MARK: - CIDR Parsing Tests

    @Test("Parse valid CIDR notation")
    func testParseValidCIDR() throws {
        let (ip, prefix) = try service.parseCIDR("192.168.1.0/24")
        #expect(ip.octets == [192, 168, 1, 0])
        #expect(prefix == 24)
    }

    @Test("Parse CIDR with /32")
    func testParseCIDRHost() throws {
        let (ip, prefix) = try service.parseCIDR("10.0.0.1/32")
        #expect(ip.octets == [10, 0, 0, 1])
        #expect(prefix == 32)
    }

    @Test("Parse CIDR with /0")
    func testParseCIDRAll() throws {
        let (ip, prefix) = try service.parseCIDR("0.0.0.0/0")
        #expect(ip.octets == [0, 0, 0, 0])
        #expect(prefix == 0)
    }

    @Test("Invalid CIDR - missing prefix")
    func testInvalidCIDRMissingPrefix() {
        #expect(throws: IPUtilitiesService.IPError.invalidCIDRNotation) {
            _ = try service.parseCIDR("192.168.1.0")
        }
    }

    @Test("Invalid CIDR - prefix out of range")
    func testInvalidCIDRPrefixOutOfRange() {
        #expect(throws: IPUtilitiesService.IPError.prefixLengthOutOfRange) {
            _ = try service.parseCIDR("192.168.1.0/33")
        }
    }

    // MARK: - Subnet Calculation Tests

    @Test("Calculate /24 subnet")
    func testCalculate24Subnet() throws {
        let info = try service.calculateSubnetFromCIDR("192.168.1.100/24")

        #expect(info.network.stringValue == "192.168.1.0")
        #expect(info.broadcast.stringValue == "192.168.1.255")
        #expect(info.firstHost.stringValue == "192.168.1.1")
        #expect(info.lastHost.stringValue == "192.168.1.254")
        #expect(info.subnetMask.stringValue == "255.255.255.0")
        #expect(info.wildcardMask.stringValue == "0.0.0.255")
        #expect(info.prefixLength == 24)
        #expect(info.totalHosts == 256)
        #expect(info.usableHosts == 254)
    }

    @Test("Calculate /16 subnet")
    func testCalculate16Subnet() throws {
        let info = try service.calculateSubnetFromCIDR("172.16.50.100/16")

        #expect(info.network.stringValue == "172.16.0.0")
        #expect(info.broadcast.stringValue == "172.16.255.255")
        #expect(info.subnetMask.stringValue == "255.255.0.0")
        #expect(info.totalHosts == 65536)
        #expect(info.usableHosts == 65534)
    }

    @Test("Calculate /30 point-to-point subnet")
    func testCalculate30Subnet() throws {
        let info = try service.calculateSubnetFromCIDR("10.0.0.4/30")

        #expect(info.network.stringValue == "10.0.0.4")
        #expect(info.broadcast.stringValue == "10.0.0.7")
        #expect(info.firstHost.stringValue == "10.0.0.5")
        #expect(info.lastHost.stringValue == "10.0.0.6")
        #expect(info.totalHosts == 4)
        #expect(info.usableHosts == 2)
    }

    @Test("Calculate /31 RFC 3021 subnet")
    func testCalculate31Subnet() throws {
        let info = try service.calculateSubnetFromCIDR("10.0.0.0/31")

        #expect(info.network.stringValue == "10.0.0.0")
        #expect(info.broadcast.stringValue == "10.0.0.1")
        #expect(info.totalHosts == 2)
        #expect(info.usableHosts == 2) // Both addresses are usable in /31
    }

    @Test("Calculate /32 host subnet")
    func testCalculate32Subnet() throws {
        let info = try service.calculateSubnetFromCIDR("10.0.0.1/32")

        #expect(info.network.stringValue == "10.0.0.1")
        #expect(info.broadcast.stringValue == "10.0.0.1")
        #expect(info.totalHosts == 1)
        #expect(info.usableHosts == 1)
    }

    // MARK: - IP Classification Tests

    @Test("Determine Class A IP")
    func testClassA() throws {
        let ip = try service.parseIPv4("10.0.0.1")
        let ipClass = service.determineIPClass(ip)
        #expect(ipClass == "A")
    }

    @Test("Determine Class B IP")
    func testClassB() throws {
        let ip = try service.parseIPv4("172.16.0.1")
        let ipClass = service.determineIPClass(ip)
        #expect(ipClass == "B")
    }

    @Test("Determine Class C IP")
    func testClassC() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        let ipClass = service.determineIPClass(ip)
        #expect(ipClass == "C")
    }

    @Test("Determine Multicast IP")
    func testMulticast() throws {
        let ip = try service.parseIPv4("224.0.0.1")
        let ipClass = service.determineIPClass(ip)
        #expect(ipClass == "D (Multicast)")
    }

    // MARK: - Private IP Tests

    @Test("Detect private Class A")
    func testPrivateClassA() throws {
        let ip = try service.parseIPv4("10.50.100.200")
        #expect(service.isPrivateIP(ip) == true)
    }

    @Test("Detect private Class B")
    func testPrivateClassB() throws {
        let ip = try service.parseIPv4("172.16.0.1")
        #expect(service.isPrivateIP(ip) == true)

        let ip2 = try service.parseIPv4("172.31.255.255")
        #expect(service.isPrivateIP(ip2) == true)

        // Non-private Class B range
        let ip3 = try service.parseIPv4("172.32.0.1")
        #expect(service.isPrivateIP(ip3) == false)
    }

    @Test("Detect private Class C")
    func testPrivateClassC() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        #expect(service.isPrivateIP(ip) == true)
    }

    @Test("Detect loopback")
    func testLoopback() throws {
        let ip = try service.parseIPv4("127.0.0.1")
        #expect(service.isPrivateIP(ip) == true)
    }

    @Test("Detect link-local")
    func testLinkLocal() throws {
        let ip = try service.parseIPv4("169.254.1.1")
        #expect(service.isPrivateIP(ip) == true)
    }

    @Test("Detect public IP")
    func testPublicIP() throws {
        let ip = try service.parseIPv4("8.8.8.8")
        #expect(service.isPrivateIP(ip) == false)
    }

    // MARK: - IP In Subnet Tests

    @Test("IP is in subnet")
    func testIPInSubnet() throws {
        let ip = try service.parseIPv4("192.168.1.50")
        let network = try service.parseIPv4("192.168.1.0")
        #expect(service.isIPInSubnet(ip: ip, network: network, prefixLength: 24) == true)
    }

    @Test("IP is not in subnet")
    func testIPNotInSubnet() throws {
        let ip = try service.parseIPv4("192.168.2.50")
        let network = try service.parseIPv4("192.168.1.0")
        #expect(service.isIPInSubnet(ip: ip, network: network, prefixLength: 24) == false)
    }

    // MARK: - Binary/Hex Representation Tests

    @Test("IPv4 binary representation")
    func testIPv4Binary() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        #expect(ip.binaryString == "11000000.10101000.00000001.00000001")
    }

    @Test("IPv4 hex representation")
    func testIPv4Hex() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        #expect(ip.hexString == "C0:A8:01:01")
    }

    @Test("IPv4 integer representation")
    func testIPv4Int() throws {
        let ip = try service.parseIPv4("192.168.1.1")
        #expect(ip.intValue == 3232235777)
    }

    // MARK: - Subnet Mask Validation Tests

    @Test("Valid subnet mask to prefix")
    func testValidSubnetMaskToPrefix() throws {
        let mask = try service.parseIPv4("255.255.255.0")
        let prefix = try service.subnetMaskToPrefixLength(mask)
        #expect(prefix == 24)
    }

    @Test("Invalid non-contiguous subnet mask")
    func testInvalidSubnetMask() throws {
        let mask = try service.parseIPv4("255.255.0.255")
        #expect(throws: IPUtilitiesService.IPError.invalidSubnetMask) {
            _ = try service.subnetMaskToPrefixLength(mask)
        }
    }

    // MARK: - Subnet Division Tests

    @Test("Divide /24 into /26 subnets")
    func testDivideSubnet() throws {
        let network = try service.parseIPv4("192.168.1.0")
        let subnets = try service.divideSubnet(network: network, prefixLength: 24, newPrefixLength: 26)

        #expect(subnets.count == 4)
        #expect(subnets[0].network.stringValue == "192.168.1.0")
        #expect(subnets[1].network.stringValue == "192.168.1.64")
        #expect(subnets[2].network.stringValue == "192.168.1.128")
        #expect(subnets[3].network.stringValue == "192.168.1.192")
    }

    // MARK: - Validation Tests

    @Test("Validate correct IPv4")
    func testValidateCorrectIPv4() {
        #expect(service.isValidIPv4("192.168.1.1") == true)
    }

    @Test("Validate incorrect IPv4")
    func testValidateIncorrectIPv4() {
        #expect(service.isValidIPv4("192.168.1.256") == false)
        #expect(service.isValidIPv4("not an ip") == false)
    }

    @Test("Validate correct CIDR")
    func testValidateCorrectCIDR() {
        #expect(service.isValidCIDR("192.168.1.0/24") == true)
    }

    @Test("Validate incorrect CIDR")
    func testValidateIncorrectCIDR() {
        #expect(service.isValidCIDR("192.168.1.0/33") == false)
        #expect(service.isValidCIDR("192.168.1.0") == false)
    }
}

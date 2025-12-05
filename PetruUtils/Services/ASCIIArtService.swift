import Foundation

/// Service for generating ASCII art from text
struct ASCIIArtService {

    // MARK: - Error Types

    enum ASCIIArtError: LocalizedError, Equatable {
        case emptyInput
        case invalidCharacter(Character)
        case fontNotSupported

        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input text cannot be empty."
            case .invalidCharacter(let char):
                return "Character '\(char)' is not supported in this font."
            case .fontNotSupported:
                return "The selected font is not available."
            }
        }
    }

    // MARK: - Font Enum

    enum ASCIIFont: String, CaseIterable, Identifiable {
        case banner
        case block
        case small
        case standard
        case mini

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .banner: return "Banner"
            case .block: return "Block"
            case .small: return "Small"
            case .standard: return "Standard"
            case .mini: return "Mini"
            }
        }
    }

    // MARK: - Character Maps

    /// Banner font character map (7 lines tall)
    private let bannerFont: [Character: [String]] = {
        var map: [Character: [String]] = [:]

        // Letters A-Z
        map["A"] = [
            "  ###  ",
            " #   # ",
            "#     #",
            "#######",
            "#     #",
            "#     #",
            "#     #"
        ]
        map["B"] = [
            "###### ",
            "#     #",
            "#     #",
            "###### ",
            "#     #",
            "#     #",
            "###### "
        ]
        map["C"] = [
            " ##### ",
            "#     #",
            "#      ",
            "#      ",
            "#      ",
            "#     #",
            " ##### "
        ]
        map["D"] = [
            "###### ",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            "###### "
        ]
        map["E"] = [
            "#######",
            "#      ",
            "#      ",
            "#####  ",
            "#      ",
            "#      ",
            "#######"
        ]
        map["F"] = [
            "#######",
            "#      ",
            "#      ",
            "#####  ",
            "#      ",
            "#      ",
            "#      "
        ]
        map["G"] = [
            " ##### ",
            "#     #",
            "#      ",
            "#  ####",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["H"] = [
            "#     #",
            "#     #",
            "#     #",
            "#######",
            "#     #",
            "#     #",
            "#     #"
        ]
        map["I"] = [
            "  ###  ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "  ###  "
        ]
        map["J"] = [
            "    ###",
            "      #",
            "      #",
            "      #",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["K"] = [
            "#    # ",
            "#   #  ",
            "#  #   ",
            "###    ",
            "#  #   ",
            "#   #  ",
            "#    # "
        ]
        map["L"] = [
            "#      ",
            "#      ",
            "#      ",
            "#      ",
            "#      ",
            "#      ",
            "#######"
        ]
        map["M"] = [
            "#     #",
            "##   ##",
            "# # # #",
            "#  #  #",
            "#     #",
            "#     #",
            "#     #"
        ]
        map["N"] = [
            "#     #",
            "##    #",
            "# #   #",
            "#  #  #",
            "#   # #",
            "#    ##",
            "#     #"
        ]
        map["O"] = [
            " ##### ",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["P"] = [
            "###### ",
            "#     #",
            "#     #",
            "###### ",
            "#      ",
            "#      ",
            "#      "
        ]
        map["Q"] = [
            " ##### ",
            "#     #",
            "#     #",
            "#     #",
            "#   # #",
            "#    # ",
            " #### #"
        ]
        map["R"] = [
            "###### ",
            "#     #",
            "#     #",
            "###### ",
            "#   #  ",
            "#    # ",
            "#     #"
        ]
        map["S"] = [
            " ##### ",
            "#     #",
            "#      ",
            " ##### ",
            "      #",
            "#     #",
            " ##### "
        ]
        map["T"] = [
            "#######",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   "
        ]
        map["U"] = [
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["V"] = [
            "#     #",
            "#     #",
            "#     #",
            "#     #",
            " #   # ",
            "  # #  ",
            "   #   "
        ]
        map["W"] = [
            "#     #",
            "#     #",
            "#     #",
            "#  #  #",
            "# # # #",
            "##   ##",
            "#     #"
        ]
        map["X"] = [
            "#     #",
            " #   # ",
            "  # #  ",
            "   #   ",
            "  # #  ",
            " #   # ",
            "#     #"
        ]
        map["Y"] = [
            "#     #",
            " #   # ",
            "  # #  ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   "
        ]
        map["Z"] = [
            "#######",
            "     # ",
            "    #  ",
            "   #   ",
            "  #    ",
            " #     ",
            "#######"
        ]

        // Numbers 0-9
        map["0"] = [
            " ##### ",
            "#     #",
            "#    ##",
            "#  #  #",
            "##    #",
            "#     #",
            " ##### "
        ]
        map["1"] = [
            "   #   ",
            "  ##   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "  ###  "
        ]
        map["2"] = [
            " ##### ",
            "#     #",
            "      #",
            " ##### ",
            "#      ",
            "#      ",
            "#######"
        ]
        map["3"] = [
            " ##### ",
            "#     #",
            "      #",
            "  #### ",
            "      #",
            "#     #",
            " ##### "
        ]
        map["4"] = [
            "#     #",
            "#     #",
            "#     #",
            "#######",
            "      #",
            "      #",
            "      #"
        ]
        map["5"] = [
            "#######",
            "#      ",
            "#      ",
            "###### ",
            "      #",
            "#     #",
            " ##### "
        ]
        map["6"] = [
            " ##### ",
            "#     #",
            "#      ",
            "###### ",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["7"] = [
            "#######",
            "      #",
            "     # ",
            "    #  ",
            "   #   ",
            "   #   ",
            "   #   "
        ]
        map["8"] = [
            " ##### ",
            "#     #",
            "#     #",
            " ##### ",
            "#     #",
            "#     #",
            " ##### "
        ]
        map["9"] = [
            " ##### ",
            "#     #",
            "#     #",
            " ######",
            "      #",
            "#     #",
            " ##### "
        ]

        // Space
        map[" "] = [
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "       "
        ]

        // Common punctuation
        map["!"] = [
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "   #   ",
            "       ",
            "   #   "
        ]
        map["?"] = [
            " ##### ",
            "#     #",
            "      #",
            "   ### ",
            "   #   ",
            "       ",
            "   #   "
        ]
        map["."] = [
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "   #   "
        ]
        map[","] = [
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "   #   ",
            "  #    "
        ]
        map["-"] = [
            "       ",
            "       ",
            "       ",
            "#######",
            "       ",
            "       ",
            "       "
        ]
        map["_"] = [
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "       ",
            "#######"
        ]
        map[":"] = [
            "       ",
            "   #   ",
            "   #   ",
            "       ",
            "   #   ",
            "   #   ",
            "       "
        ]
        map["@"] = [
            " ##### ",
            "#     #",
            "# ### #",
            "# # # #",
            "# #### ",
            "#      ",
            " ##### "
        ]

        return map
    }()

    /// Block font character map (5 lines tall)
    private let blockFont: [Character: [String]] = {
        var map: [Character: [String]] = [:]

        map["A"] = ["█████", "█   █", "█████", "█   █", "█   █"]
        map["B"] = ["████ ", "█   █", "████ ", "█   █", "████ "]
        map["C"] = ["█████", "█    ", "█    ", "█    ", "█████"]
        map["D"] = ["████ ", "█   █", "█   █", "█   █", "████ "]
        map["E"] = ["█████", "█    ", "████ ", "█    ", "█████"]
        map["F"] = ["█████", "█    ", "████ ", "█    ", "█    "]
        map["G"] = ["█████", "█    ", "█ ███", "█   █", "█████"]
        map["H"] = ["█   █", "█   █", "█████", "█   █", "█   █"]
        map["I"] = ["█████", "  █  ", "  █  ", "  █  ", "█████"]
        map["J"] = ["█████", "    █", "    █", "█   █", " ███ "]
        map["K"] = ["█   █", "█  █ ", "███  ", "█  █ ", "█   █"]
        map["L"] = ["█    ", "█    ", "█    ", "█    ", "█████"]
        map["M"] = ["█   █", "██ ██", "█ █ █", "█   █", "█   █"]
        map["N"] = ["█   █", "██  █", "█ █ █", "█  ██", "█   █"]
        map["O"] = [" ███ ", "█   █", "█   █", "█   █", " ███ "]
        map["P"] = ["████ ", "█   █", "████ ", "█    ", "█    "]
        map["Q"] = [" ███ ", "█   █", "█ █ █", "█  █ ", " ██ █"]
        map["R"] = ["████ ", "█   █", "████ ", "█  █ ", "█   █"]
        map["S"] = [" ████", "█    ", " ███ ", "    █", "████ "]
        map["T"] = ["█████", "  █  ", "  █  ", "  █  ", "  █  "]
        map["U"] = ["█   █", "█   █", "█   █", "█   █", " ███ "]
        map["V"] = ["█   █", "█   █", "█   █", " █ █ ", "  █  "]
        map["W"] = ["█   █", "█   █", "█ █ █", "██ ██", "█   █"]
        map["X"] = ["█   █", " █ █ ", "  █  ", " █ █ ", "█   █"]
        map["Y"] = ["█   █", " █ █ ", "  █  ", "  █  ", "  █  "]
        map["Z"] = ["█████", "   █ ", "  █  ", " █   ", "█████"]

        map["0"] = [" ███ ", "█  ██", "█ █ █", "██  █", " ███ "]
        map["1"] = [" ██  ", "  █  ", "  █  ", "  █  ", " ███ "]
        map["2"] = [" ███ ", "█   █", "  ██ ", " █   ", "█████"]
        map["3"] = [" ███ ", "    █", " ███ ", "    █", " ███ "]
        map["4"] = ["█   █", "█   █", "█████", "    █", "    █"]
        map["5"] = ["█████", "█    ", "████ ", "    █", "████ "]
        map["6"] = [" ███ ", "█    ", "████ ", "█   █", " ███ "]
        map["7"] = ["█████", "    █", "   █ ", "  █  ", "  █  "]
        map["8"] = [" ███ ", "█   █", " ███ ", "█   █", " ███ "]
        map["9"] = [" ███ ", "█   █", " ████", "    █", " ███ "]

        map[" "] = ["     ", "     ", "     ", "     ", "     "]
        map["!"] = ["  █  ", "  █  ", "  █  ", "     ", "  █  "]
        map["?"] = [" ███ ", "    █", "  █  ", "     ", "  █  "]
        map["."] = ["     ", "     ", "     ", "     ", "  █  "]
        map["-"] = ["     ", "     ", "█████", "     ", "     "]

        return map
    }()

    /// Small font character map (3 lines tall)
    private let smallFont: [Character: [String]] = {
        var map: [Character: [String]] = [:]

        map["A"] = [" # ", "###", "# #"]
        map["B"] = ["## ", "## ", "## "]
        map["C"] = [" ##", "#  ", " ##"]
        map["D"] = ["## ", "# #", "## "]
        map["E"] = ["###", "## ", "###"]
        map["F"] = ["###", "## ", "#  "]
        map["G"] = [" ##", "# #", " ##"]
        map["H"] = ["# #", "###", "# #"]
        map["I"] = ["###", " # ", "###"]
        map["J"] = ["###", "  #", "## "]
        map["K"] = ["# #", "## ", "# #"]
        map["L"] = ["#  ", "#  ", "###"]
        map["M"] = ["# #", "###", "# #"]
        map["N"] = ["# #", "###", "# #"]
        map["O"] = ["###", "# #", "###"]
        map["P"] = ["###", "###", "#  "]
        map["Q"] = ["###", "###", " ##"]
        map["R"] = ["###", "## ", "# #"]
        map["S"] = [" ##", " # ", "## "]
        map["T"] = ["###", " # ", " # "]
        map["U"] = ["# #", "# #", "###"]
        map["V"] = ["# #", "# #", " # "]
        map["W"] = ["# #", "###", "# #"]
        map["X"] = ["# #", " # ", "# #"]
        map["Y"] = ["# #", " # ", " # "]
        map["Z"] = ["## ", " # ", " ##"]

        map["0"] = ["###", "# #", "###"]
        map["1"] = [" # ", "## ", " # "]
        map["2"] = ["## ", " # ", " ##"]
        map["3"] = ["## ", " # ", "## "]
        map["4"] = ["# #", "###", "  #"]
        map["5"] = [" ##", " # ", "## "]
        map["6"] = ["#  ", "###", "###"]
        map["7"] = ["###", "  #", "  #"]
        map["8"] = ["###", "###", "###"]
        map["9"] = ["###", "###", "  #"]

        map[" "] = ["   ", "   ", "   "]
        map["!"] = [" # ", " # ", " # "]
        map["."] = ["   ", "   ", " # "]

        return map
    }()

    /// Standard font (5 lines, narrower than block)
    private let standardFont: [Character: [String]] = {
        var map: [Character: [String]] = [:]

        map["A"] = [" /\\ ", "/  \\", "/--\\", "/  \\", "/  \\"]
        map["B"] = ["|--\\", "|__/", "|--\\", "|  |", "|__/"]
        map["C"] = [" __", "/  ", "|  ", "\\__", "   "]
        map["D"] = ["|--\\", "|  |", "|  |", "|  |", "|__/"]
        map["E"] = ["|--", "|__", "|--", "|  ", "|__"]
        map["F"] = ["|--", "|__", "|--", "|  ", "|  "]
        map["G"] = [" __", "/  ", "| _", "\\_|", "   "]
        map["H"] = ["|  |", "|__|", "|  |", "|  |", "|  |"]
        map["I"] = ["---", " | ", " | ", " | ", "---"]
        map["J"] = ["  |", "  |", "  |", "\\_|", "   "]
        map["K"] = ["|  /", "| / ", "|/  ", "|\\ ", "| \\"]
        map["L"] = ["|  ", "|  ", "|  ", "|  ", "|__"]
        map["M"] = ["|\\  /|", "| \\/ |", "|    |", "|    |", "|    |"]
        map["N"] = ["|\\  |", "| \\ |", "|  \\|", "|   |", "|   |"]
        map["O"] = [" __ ", "/  \\", "|  |", "\\__/", "    "]
        map["P"] = ["|--\\", "|__/", "|   ", "|   ", "|   "]
        map["Q"] = [" __ ", "/  \\", "|  |", "\\__/", "   \\"]
        map["R"] = ["|--\\", "|__/", "| \\ ", "|  \\", "|   \\"]
        map["S"] = [" __", "/  ", "\\__", "  \\", "__/"]
        map["T"] = ["---", " | ", " | ", " | ", " | "]
        map["U"] = ["|  |", "|  |", "|  |", "\\__/", "    "]
        map["V"] = ["\\  /", " \\/ ", "    ", "    ", "    "]
        map["W"] = ["|    |", "|    |", "| /\\ |", "|/  \\|", "      "]
        map["X"] = ["\\  /", " \\/ ", " /\\ ", "/  \\", "    "]
        map["Y"] = ["\\  /", " \\/ ", " |  ", " |  ", " |  "]
        map["Z"] = ["----", "  / ", " /  ", "/   ", "----"]

        map["0"] = [" __ ", "/  \\", "| /|", "|/ |", "\\__/"]
        map["1"] = [" / ", "// ", " | ", " | ", "---"]
        map["2"] = [" __ ", "/  \\", "  / ", " /  ", "/___"]
        map["3"] = ["__  ", "  \\ ", " __ ", "   \\", "___/"]
        map["4"] = ["   /", "  / ", " /__|", "   |", "   |"]
        map["5"] = [" ___", "|   ", "|__ ", "   \\", "___/"]
        map["6"] = [" __ ", "/   ", "|__ ", "|  \\", "\\__/"]
        map["7"] = ["____", "   /", "  / ", " /  ", "/   "]
        map["8"] = [" __ ", "(  )", " )( ", "(  )", " -- "]
        map["9"] = [" __ ", "/  \\", "\\__|", "   |", "   |"]

        map[" "] = ["    ", "    ", "    ", "    ", "    "]
        map["!"] = [" | ", " | ", " | ", "   ", " o "]
        map["."] = ["   ", "   ", "   ", "   ", " . "]

        return map
    }()

    /// Mini font (2 lines tall)
    private let miniFont: [Character: [String]] = {
        var map: [Character: [String]] = [:]

        map["A"] = ["/\\", "##"]
        map["B"] = ["B", "B"]
        map["C"] = ["C", "C"]
        map["D"] = ["D", "D"]
        map["E"] = ["E", "E"]
        map["F"] = ["F", "F"]
        map["G"] = ["G", "G"]
        map["H"] = ["H", "H"]
        map["I"] = ["I", "I"]
        map["J"] = ["J", "J"]
        map["K"] = ["K", "K"]
        map["L"] = ["L", "L"]
        map["M"] = ["M", "M"]
        map["N"] = ["N", "N"]
        map["O"] = ["O", "O"]
        map["P"] = ["P", "P"]
        map["Q"] = ["Q", "Q"]
        map["R"] = ["R", "R"]
        map["S"] = ["S", "S"]
        map["T"] = ["T", "T"]
        map["U"] = ["U", "U"]
        map["V"] = ["\\/", " V"]
        map["W"] = ["W", "W"]
        map["X"] = ["X", "X"]
        map["Y"] = ["Y", "Y"]
        map["Z"] = ["Z", "Z"]

        map["0"] = ["0", "0"]
        map["1"] = ["1", "1"]
        map["2"] = ["2", "2"]
        map["3"] = ["3", "3"]
        map["4"] = ["4", "4"]
        map["5"] = ["5", "5"]
        map["6"] = ["6", "6"]
        map["7"] = ["7", "7"]
        map["8"] = ["8", "8"]
        map["9"] = ["9", "9"]

        map[" "] = [" ", " "]

        return map
    }()

    // MARK: - Public Methods

    /// Generate ASCII art from text using the specified font
    func generateASCIIArt(from text: String, font: ASCIIFont) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw ASCIIArtError.emptyInput
        }

        let uppercased = trimmed.uppercased()
        let fontMap = getFontMap(for: font)
        let lineCount = getLineCount(for: font)

        // Initialize result lines
        var resultLines = Array(repeating: "", count: lineCount)

        // Process each character
        for char in uppercased {
            guard let charLines = fontMap[char] else {
                // For unsupported characters, try using space
                if let spaceLines = fontMap[" "] {
                    for i in 0..<lineCount {
                        resultLines[i] += spaceLines[i]
                    }
                }
                continue
            }

            for i in 0..<min(lineCount, charLines.count) {
                resultLines[i] += charLines[i]
            }
        }

        return resultLines.joined(separator: "\n")
    }

    /// Get list of supported characters for a font
    func supportedCharacters(for font: ASCIIFont) -> [Character] {
        return Array(getFontMap(for: font).keys).sorted()
    }

    /// Check if a character is supported in a font
    func isCharacterSupported(_ char: Character, font: ASCIIFont) -> Bool {
        let uppercased = char.uppercased().first ?? char
        return getFontMap(for: font)[uppercased] != nil
    }

    // MARK: - Private Helpers

    private func getFontMap(for font: ASCIIFont) -> [Character: [String]] {
        switch font {
        case .banner:
            return bannerFont
        case .block:
            return blockFont
        case .small:
            return smallFont
        case .standard:
            return standardFont
        case .mini:
            return miniFont
        }
    }

    private func getLineCount(for font: ASCIIFont) -> Int {
        switch font {
        case .banner:
            return 7
        case .block, .standard:
            return 5
        case .small:
            return 3
        case .mini:
            return 2
        }
    }
}

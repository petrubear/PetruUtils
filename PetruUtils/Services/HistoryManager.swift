import Foundation
import Combine

/// Manager for tracking tool usage history, favorites, and recent conversions
@MainActor
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    private let defaults = UserDefaults.standard
    private let preferencesManager = PreferencesManager.shared
    
    // MARK: - Published Properties
    
    @Published var recentTools: [Tool] = []
    @Published var favoriteTools: Set<Tool> = []
    @Published private(set) var conversionHistory: [Tool: [HistoryItem]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadRecentTools()
        loadFavoriteTools()
        loadConversionHistory()
        cleanupOldHistory()
    }
    
    // MARK: - Recent Tools
    
    /// Record that a tool was used
    func recordToolUsage(_ tool: Tool) {
        // Remove if already exists to avoid duplicates
        recentTools.removeAll { $0 == tool }
        
        // Add to front
        recentTools.insert(tool, at: 0)
        
        // Keep only the last 5 tools
        if recentTools.count > 5 {
            recentTools = Array(recentTools.prefix(5))
        }
        
        saveRecentTools()
    }
    
    /// Clear all recent tools
    func clearRecentTools() {
        recentTools.removeAll()
        saveRecentTools()
    }
    
    private func loadRecentTools() {
        if let data = defaults.data(forKey: HistoryKeys.recentTools),
           let tools = try? JSONDecoder().decode([String].self, from: data) {
            recentTools = tools.compactMap { Tool(rawValue: $0) }
        }
    }
    
    private func saveRecentTools() {
        let toolStrings = recentTools.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(toolStrings) {
            defaults.set(data, forKey: HistoryKeys.recentTools)
        }
    }
    
    // MARK: - Favorites
    
    /// Toggle favorite status for a tool
    func toggleFavorite(_ tool: Tool) {
        if favoriteTools.contains(tool) {
            favoriteTools.remove(tool)
        } else {
            favoriteTools.insert(tool)
        }
        saveFavoriteTools()
    }
    
    /// Check if a tool is favorited
    func isFavorite(_ tool: Tool) -> Bool {
        favoriteTools.contains(tool)
    }
    
    /// Get sorted list of favorite tools
    var sortedFavorites: [Tool] {
        favoriteTools.sorted { $0.title < $1.title }
    }
    
    private func loadFavoriteTools() {
        if let data = defaults.data(forKey: HistoryKeys.favoriteTools),
           let tools = try? JSONDecoder().decode([String].self, from: data) {
            favoriteTools = Set(tools.compactMap { Tool(rawValue: $0) })
        }
    }
    
    private func saveFavoriteTools() {
        let toolStrings = Array(favoriteTools).map { $0.rawValue }
        if let data = try? JSONEncoder().encode(toolStrings) {
            defaults.set(data, forKey: HistoryKeys.favoriteTools)
        }
    }
    
    // MARK: - Conversion History
    
    /// Add a conversion to history for a specific tool
    func addConversion(_ item: HistoryItem, for tool: Tool) {
        guard preferencesManager.historyEnabled else { return }
        
        var items = conversionHistory[tool] ?? []
        
        // Add new item at the front
        items.insert(item, at: 0)
        
        // Limit to max items per tool
        let maxItems = preferencesManager.historyMaxItems
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        conversionHistory[tool] = items
        saveConversionHistory(for: tool)
    }
    
    /// Get conversion history for a specific tool
    func getHistory(for tool: Tool) -> [HistoryItem] {
        conversionHistory[tool] ?? []
    }
    
    /// Clear history for a specific tool
    func clearHistory(for tool: Tool) {
        conversionHistory[tool] = nil
        defaults.removeObject(forKey: historyKey(for: tool))
    }
    
    /// Clear all conversion history
    func clearAllHistory() {
        conversionHistory.removeAll()
        
        // Remove all history keys from UserDefaults
        for tool in Tool.allCases {
            defaults.removeObject(forKey: historyKey(for: tool))
        }
    }
    
    /// Clean up old history items based on retention period
    private func cleanupOldHistory() {
        guard preferencesManager.historyEnabled else { return }
        
        let retentionDays = preferencesManager.historyRetentionDays
        guard retentionDays != 999999 else { return } // Forever
        
        let cutoffDate = Date().addingTimeInterval(-Double(retentionDays * 24 * 60 * 60))
        
        for tool in Tool.allCases {
            if var items = conversionHistory[tool] {
                items.removeAll { $0.timestamp < cutoffDate }
                conversionHistory[tool] = items
                saveConversionHistory(for: tool)
            }
        }
    }
    
    private func loadConversionHistory() {
        guard preferencesManager.historyEnabled else { return }
        
        for tool in Tool.allCases {
            if let data = defaults.data(forKey: historyKey(for: tool)),
               let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
                conversionHistory[tool] = items
            }
        }
    }
    
    private func saveConversionHistory(for tool: Tool) {
        guard let items = conversionHistory[tool] else { return }
        
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: historyKey(for: tool))
        }
    }
    
    private func historyKey(for tool: Tool) -> String {
        "\(HistoryKeys.conversionHistory).\(tool.rawValue)"
    }
}

// MARK: - Supporting Types

/// Represents a single conversion/operation in history
struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let input: String
    let output: String
    let metadata: [String: String]?
    
    init(input: String, output: String, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.input = input
        self.output = output
        self.metadata = metadata
    }
    
    /// Formatted relative time (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Truncated input preview (first 50 chars)
    var inputPreview: String {
        if input.count > 50 {
            return String(input.prefix(50)) + "..."
        }
        return input
    }
    
    /// Truncated output preview (first 50 chars)
    var outputPreview: String {
        if output.count > 50 {
            return String(output.prefix(50)) + "..."
        }
        return output
    }
}

// MARK: - History Keys

private struct HistoryKeys {
    static let recentTools = "history.recentTools"
    static let favoriteTools = "history.favoriteTools"
    static let conversionHistory = "history.conversions"
}

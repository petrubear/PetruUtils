import Foundation
import AppKit
import UniformTypeIdentifiers

/// Utility for exporting and importing files
struct FileExportImport {
    
    // MARK: - Export
    
    /// Export text content to a file with save dialog
    /// - Parameters:
    ///   - content: The text content to export
    ///   - defaultFilename: Default filename to suggest
    ///   - fileExtension: File extension (e.g., "txt", "json", "xml")
    /// - Returns: True if export succeeded, false otherwise
    @MainActor
    static func exportText(
        content: String,
        defaultFilename: String,
        fileExtension: String
    ) -> Bool {
        let savePanel = NSSavePanel()
        savePanel.title = "Export File"
        savePanel.nameFieldStringValue = defaultFilename
        if let utType = UTType(filenameExtension: fileExtension) {
            savePanel.allowedContentTypes = [utType]
        }
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            return false
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            showError(message: "Failed to export file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Export data to a file with save dialog
    /// - Parameters:
    ///   - data: The binary data to export
    ///   - defaultFilename: Default filename to suggest
    ///   - fileExtension: File extension
    /// - Returns: True if export succeeded, false otherwise
    @MainActor
    static func exportData(
        data: Data,
        defaultFilename: String,
        fileExtension: String
    ) -> Bool {
        let savePanel = NSSavePanel()
        savePanel.title = "Export File"
        savePanel.nameFieldStringValue = defaultFilename
        if let utType = UTType(filenameExtension: fileExtension) {
            savePanel.allowedContentTypes = [utType]
        }
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            return false
        }
        
        do {
            try data.write(to: url)
            return true
        } catch {
            showError(message: "Failed to export file: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Import
    
    /// Import text content from a file with open dialog
    /// - Parameter allowedExtensions: Array of allowed file extensions (e.g., ["txt", "json"])
    /// - Returns: The imported text content, or nil if cancelled or failed
    @MainActor
    static func importText(allowedExtensions: [String]? = nil) -> String? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import File"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if let extensions = allowedExtensions {
            openPanel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        }
        
        guard openPanel.runModal() == .OK,
              let url = openPanel.url else {
            return nil
        }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            showError(message: "Failed to import file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Import binary data from a file with open dialog
    /// - Parameter allowedExtensions: Array of allowed file extensions
    /// - Returns: The imported data, or nil if cancelled or failed
    @MainActor
    static func importData(allowedExtensions: [String]? = nil) -> Data? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import File"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if let extensions = allowedExtensions {
            openPanel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        }
        
        guard openPanel.runModal() == .OK,
              let url = openPanel.url else {
            return nil
        }
        
        do {
            return try Data(contentsOf: url)
        } catch {
            showError(message: "Failed to import file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper
    
    @MainActor
    private static func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Common File Extensions

extension FileExportImport {
    struct FileExtensions {
        static let json = "json"
        static let xml = "xml"
        static let html = "html"
        static let css = "css"
        static let sql = "sql"
        static let yaml = "yaml"
        static let yml = "yml"
        static let csv = "csv"
        static let txt = "txt"
        static let md = "md"
        static let png = "png"
        static let svg = "svg"
    }
}

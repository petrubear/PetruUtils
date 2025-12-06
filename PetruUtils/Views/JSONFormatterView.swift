import SwiftUI
import Combine

struct JSONFormatterView: View {
    @StateObject private var vm = JSONFormatterViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                inputPane
                outputPane
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("JSON Formatter").font(.headline)
            Spacer()

            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "doc.text", title: "Input JSON", color: .blue)

                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))

                    HStack {
                        if !vm.input.isEmpty {
                            Text("\(vm.input.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Divider()

                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Indentation")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.indentStyle) {
                            Text("2 Spaces").tag(JSONFormatterService.IndentStyle.twoSpaces)
                            Text("4 Spaces").tag(JSONFormatterService.IndentStyle.fourSpaces)
                            Text("Tabs").tag(JSONFormatterService.IndentStyle.tabs)
                        }
                        .frame(width: 120)
                        .labelsHidden()
                    }

                    Divider()

                    Toggle("Sort Keys", isOn: $vm.sortKeys)
                        .toggleStyle(.switch)

                    Divider()

                    Toggle("Show Line Numbers", isOn: $vm.showLineNumbers)
                        .toggleStyle(.switch)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(#"{"name":"John","age":30,"city":"NYC"}"#)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Output")
                    .font(.headline)

                Spacer()

                // View mode toggle
                Picker("", selection: $vm.viewMode) {
                    Text("Text").tag(JSONFormatterViewModel.ViewMode.text)
                    Text("Tree").tag(JSONFormatterViewModel.ViewMode.tree)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 120)

                if !vm.output.isEmpty || vm.treeRoot != nil {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)

                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()

            // JSONPath breadcrumbs
            if !vm.selectedPath.isEmpty {
                JSONPathBreadcrumbs(path: vm.selectedPath, onCopy: vm.copyPath)
            }

            Divider()

            if let validation = vm.validationResult {
                HStack(spacing: 8) {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(validation.isValid ? .green : .red)

                    if validation.isValid {
                        Text("Valid JSON")
                            .foregroundStyle(.green)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(validation.error ?? "Invalid JSON")
                                .foregroundStyle(.red)
                                .font(.system(.body, design: .monospaced))
                            if let line = validation.lineNumber, let col = validation.columnNumber {
                                Text("Line \(line), Column \(col)")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            }

            // Content area
            if vm.viewMode == .tree, let root = vm.treeRoot {
                ScrollView {
                    JSONTreeView(node: root, selectedPath: $vm.selectedPath)
                        .padding(8)
                }
            } else if !vm.output.isEmpty {
                if vm.showLineNumbers {
                    LineNumberedCodeView(text: vm.output, language: .json)
                } else {
                    ScrollView {
                        SyntaxHighlightedText(text: vm.output, language: .json)
                            .padding(8)
                    }
                }
            } else if vm.validationResult == nil {
                VStack(spacing: 12) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Format, minify, or validate JSON")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Validation result shown, no output - show empty spacer
                Spacer()
            }
        }
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

// MARK: - JSONPath Breadcrumbs View

struct JSONPathBreadcrumbs: View {
    let path: String
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(pathComponents, id: \.self) { component in
                        HStack(spacing: 2) {
                            if component != pathComponents.first {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(component)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Copy JSONPath")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05))
    }

    private var pathComponents: [String] {
        // Parse path like $.users[0].name into components
        var components: [String] = []
        var current = ""
        var inBracket = false

        for char in path {
            if char == "[" {
                if !current.isEmpty {
                    components.append(current)
                    current = ""
                }
                inBracket = true
                current.append(char)
            } else if char == "]" {
                current.append(char)
                components.append(current)
                current = ""
                inBracket = false
            } else if char == "." && !inBracket {
                if !current.isEmpty {
                    components.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            components.append(current)
        }
        return components
    }
}

// MARK: - JSON Tree View

struct JSONTreeView: View {
    @ObservedObject var node: JSONFormatterService.JSONTreeNode
    @Binding var selectedPath: String
    var depth: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JSONTreeNodeRow(
                node: node,
                depth: depth,
                isSelected: selectedPath == node.path,
                onSelect: { selectedPath = node.path },
                onToggle: { node.isExpanded.toggle() }
            )

            if node.isExpanded && node.isExpandable {
                ForEach(node.children) { child in
                    JSONTreeView(node: child, selectedPath: $selectedPath, depth: depth + 1)
                }
            }
        }
    }
}

struct JSONTreeNodeRow: View {
    @ObservedObject var node: JSONFormatterService.JSONTreeNode
    let depth: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            // Indentation
            ForEach(0..<depth, id: \.self) { _ in
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1)
                    .padding(.leading, 8)
            }

            // Expand/collapse button
            if node.isExpandable {
                Button(action: onToggle) {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            } else {
                Spacer().frame(width: 16)
            }

            // Key
            if let key = node.key, !key.isEmpty {
                Text(key.hasPrefix("[") ? key : "\"\(key)\"")
                    .font(.code)
                    .foregroundStyle(keyColor)
                Text(":")
                    .font(.code)
                    .foregroundStyle(.secondary)
            }

            // Value or type indicator
            switch node.value {
            case .object, .array:
                Text(node.typeLabel)
                    .font(.code)
                    .foregroundStyle(.secondary)
            case .string(let s):
                Text("\"\(s)\"")
                    .font(.code)
                    .foregroundStyle(stringColor)
                    .lineLimit(1)
            case .number(let n):
                Text(n.stringValue)
                    .font(.code)
                    .foregroundStyle(numberColor)
            case .bool(let b):
                Text(b ? "true" : "false")
                    .font(.code)
                    .foregroundStyle(boolColor)
            case .null:
                Text("null")
                    .font(.code)
                    .foregroundStyle(nullColor)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private var keyColor: Color { Color(red: 0.6, green: 0.8, blue: 1.0) }
    private var stringColor: Color { Color(red: 0.8, green: 0.9, blue: 0.7) }
    private var numberColor: Color { Color(red: 0.7, green: 0.9, blue: 0.7) }
    private var boolColor: Color { Color(red: 0.8, green: 0.6, blue: 1.0) }
    private var nullColor: Color { Color(red: 1.0, green: 0.6, blue: 0.6) }
}

// MARK: - Line Numbered Code View

struct LineNumberedCodeView: View {
    let text: String
    let language: SyntaxLanguage

    private var lines: [String] {
        text.components(separatedBy: "\n")
    }

    private var lineNumberWidth: CGFloat {
        let maxLineNumber = lines.count
        let digitCount = String(maxLineNumber).count
        return CGFloat(digitCount * 10 + 16)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                        Text("\(index + 1)")
                            .font(.code)
                            .foregroundStyle(.secondary)
                            .frame(height: 20)
                    }
                }
                .frame(width: lineNumberWidth)
                .padding(.trailing, 8)
                .background(Color.secondary.opacity(0.05))

                Divider()

                // Code content
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        SyntaxHighlightedText(text: line, language: language)
                            .frame(height: 20, alignment: .leading)
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - View Model

@MainActor
final class JSONFormatterViewModel: ObservableObject {
    enum ViewMode {
        case text
        case tree
    }

    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var validationResult: JSONFormatterService.ValidationResult?
    @Published var indentStyle: JSONFormatterService.IndentStyle = .twoSpaces
    @Published var sortKeys = false
    @Published var showLineNumbers = false
    @Published var viewMode: ViewMode = .text
    @Published var treeRoot: JSONFormatterService.JSONTreeNode?
    @Published var selectedPath = ""

    private let service = JSONFormatterService()

    func format() {
        errorMessage = nil
        validationResult = nil
        treeRoot = nil
        selectedPath = ""
        guard !input.isEmpty else { return }

        do {
            output = try service.format(input, indent: indentStyle, sortKeys: sortKeys)
            // Also parse tree for tree view
            treeRoot = try service.parseToTree(input)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func minify() {
        errorMessage = nil
        validationResult = nil
        treeRoot = nil
        selectedPath = ""
        guard !input.isEmpty else { return }

        do {
            output = try service.minify(input)
            // Also parse tree for tree view
            treeRoot = try service.parseToTree(input)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func validate() {
        errorMessage = nil
        output = ""
        treeRoot = nil
        selectedPath = ""
        guard !input.isEmpty else { return }

        validationResult = service.validate(input)
        if let result = validationResult, result.isValid {
            // Parse tree if valid
            do {
                treeRoot = try service.parseToTree(input)
            } catch {
                // Ignore tree parse errors during validation
            }
        }
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        validationResult = nil
        treeRoot = nil
        selectedPath = ""
    }

    func copyOutput() {
        guard !output.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }

    func copyPath() {
        guard !selectedPath.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(selectedPath, forType: .string)
    }
}

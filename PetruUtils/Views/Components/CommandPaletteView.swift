import SwiftUI
import AppKit

/// A command palette overlay for quickly switching between tools using Cmd+K
struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @Binding var selectedTool: Tool?
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0

    private var filteredTools: [Tool] {
        if searchText.isEmpty {
            return Tool.allCases.sorted { $0.title.lowercased() < $1.title.lowercased() }
        }
        let query = searchText.lowercased()
        return Tool.allCases
            .filter {
                $0.title.lowercased().contains(query) ||
                $0.rawValue.lowercased().contains(query)
            }
            .sorted { $0.title.lowercased() < $1.title.lowercased() }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                CommandPaletteSearchField(
                    text: $searchText,
                    selectedIndex: $selectedIndex,
                    itemCount: filteredTools.count,
                    onSelect: { selectCurrentTool() },
                    onCancel: { isPresented = false }
                )
                .frame(height: 24)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            // Results list
            if filteredTools.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "commandPalette.noResults"))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(filteredTools.enumerated()), id: \.element.id) { index, tool in
                                CommandPaletteRow(
                                    tool: tool,
                                    isSelected: index == selectedIndex
                                )
                                .id(index)
                                .onTapGesture {
                                    selectTool(tool)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }

            Divider()

            // Keyboard hints
            HStack(spacing: 16) {
                keyboardHint(keys: ["↑", "↓"], action: String(localized: "commandPalette.hint.navigate"))
                keyboardHint(keys: ["↵"], action: String(localized: "commandPalette.hint.select"))
                keyboardHint(keys: ["esc"], action: String(localized: "commandPalette.hint.close"))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 500, height: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            searchText = ""
            selectedIndex = 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
    }

    private func keyboardHint(keys: [String], action: String) -> some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .tertiaryLabelColor).opacity(0.3))
                    .cornerRadius(4)
            }
            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func selectCurrentTool() {
        guard !filteredTools.isEmpty, selectedIndex < filteredTools.count else { return }
        selectTool(filteredTools[selectedIndex])
    }

    private func selectTool(_ tool: Tool) {
        selectedTool = tool
        isPresented = false
    }
}

// MARK: - Custom Search Field with keyboard handling

struct CommandPaletteSearchField: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedIndex: Int
    let itemCount: Int
    let onSelect: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.placeholderString = String(localized: "commandPalette.searchPlaceholder")
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 16)

        // Store coordinator reference for the custom field editor
        context.coordinator.textField = textField

        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }

        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
        context.coordinator.itemCount = itemCount
        context.coordinator.onSelect = onSelect
        context.coordinator.onCancel = onCancel
        context.coordinator.selectedIndexBinding = $selectedIndex
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate, NSTextViewDelegate {
        var parent: CommandPaletteSearchField
        var textField: NSTextField?
        var itemCount: Int = 0
        var onSelect: (() -> Void)?
        var onCancel: (() -> Void)?
        var selectedIndexBinding: Binding<Int>?

        init(_ parent: CommandPaletteSearchField) {
            self.parent = parent
            self.itemCount = parent.itemCount
            self.onSelect = parent.onSelect
            self.onCancel = parent.onCancel
            self.selectedIndexBinding = parent.$selectedIndex
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            DispatchQueue.main.async {
                self.parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                if let binding = selectedIndexBinding, binding.wrappedValue > 0 {
                    binding.wrappedValue -= 1
                }
                return true
            } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
                if let binding = selectedIndexBinding, binding.wrappedValue < itemCount - 1 {
                    binding.wrappedValue += 1
                }
                return true
            } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSelect?()
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onCancel?()
                return true
            }
            return false
        }
    }
}

// MARK: - Command Palette Row

struct CommandPaletteRow: View {
    let tool: Tool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.iconName)
                .frame(width: 24)
                .foregroundStyle(isSelected ? .white : .secondary)

            Text(tool.title)
                .foregroundStyle(isSelected ? .white : .primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Overlay Modifier

struct CommandPaletteOverlay: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedTool: Tool?

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isPresented = false
                            }

                        CommandPaletteView(
                            isPresented: $isPresented,
                            selectedTool: $selectedTool
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.easeOut(duration: 0.15), value: isPresented)
    }
}

extension View {
    func commandPalette(isPresented: Binding<Bool>, selectedTool: Binding<Tool?>) -> some View {
        modifier(CommandPaletteOverlay(isPresented: isPresented, selectedTool: selectedTool))
    }
}

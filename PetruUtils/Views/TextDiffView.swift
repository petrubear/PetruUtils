import SwiftUI
import Combine

struct TextDiffView: View {
    @StateObject private var vm = TextDiffViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                leftPane
                rightPane
            }
            if let result = vm.result {
                Divider()
                statsBar(result: result)
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            Text("Text Diff").font(.headline)
            Spacer()
            Toggle("Ignore Whitespace", isOn: $vm.ignoreWhitespace)
            Button("Compare") { vm.compare() }.keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Original").font(.headline)
            if let result = vm.result {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(result.leftLines.enumerated()), id: \.offset) { _, diff in
                            diffLine(diff, showLineNumber: true)
                        }
                    }
                }
            } else {
                FocusableTextEditor(text: $vm.leftText)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        .padding()
    }
    
    private var rightPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modified").font(.headline)
            if let result = vm.result {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(result.rightLines.enumerated()), id: \.offset) { _, diff in
                            diffLine(diff, showLineNumber: true)
                        }
                    }
                }
            } else {
                FocusableTextEditor(text: $vm.rightText)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func diffLine(_ diff: TextDiffService.LineDiff, showLineNumber: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if showLineNumber {
                Text("\(diff.lineNumber)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            Text(diff.content.isEmpty ? " " : diff.content)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(backgroundColor(for: diff.type))
    }
    
    private func backgroundColor(for type: TextDiffService.DiffType) -> Color {
        switch type {
        case .added: return Color.green.opacity(0.15)
        case .removed: return Color.red.opacity(0.15)
        case .unchanged: return Color.clear
        }
    }
    
    @ViewBuilder
    private func statsBar(result: TextDiffService.DiffResult) -> some View {
        HStack(spacing: 20) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                Text("\(result.addedCount) added").font(.caption)
            }
            HStack(spacing: 4) {
                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                Text("\(result.removedCount) removed").font(.caption)
            }
            HStack(spacing: 4) {
                Image(systemName: "equal.circle.fill").foregroundStyle(.secondary)
                Text("\(result.unchangedCount) unchanged").font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
}

@MainActor
final class TextDiffViewModel: ObservableObject {
    @Published var leftText = ""
    @Published var rightText = ""
    @Published var ignoreWhitespace = false
    @Published var result: TextDiffService.DiffResult?
    
    private let service = TextDiffService()
    
    func compare() {
        result = service.compare(left: leftText, right: rightText, ignoreWhitespace: ignoreWhitespace)
    }
    
    func clear() {
        leftText = ""
        rightText = ""
        result = nil
    }
}


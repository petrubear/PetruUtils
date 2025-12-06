import SwiftUI
import Combine

struct RegExpTesterView: View {
    @StateObject private var vm = RegExpTesterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            VStack(spacing: 0) {
                inputPane
                Divider()
                HSplitView {
                    testStringPane
                    resultsPane
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("RegExp Tester")
                .font(.headline)
            
            Spacer()
            
            Button("Test") { vm.test() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(icon: "asterisk.circle", title: "Pattern", color: .blue)
                Spacer()
                Menu("Common Patterns") {
                    ForEach(RegExpTesterService.commonPatterns, id: \.name) {
                        pattern in Button(pattern.name) { vm.loadPattern(pattern.pattern) }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            
            HStack {
                TextField("Enter regex pattern, e.g., \\d+", text: $vm.pattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Toggle("Case Insensitive", isOn: $vm.caseInsensitive)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help("Case Insensitive (i)")
            }
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.02))
    }
    
    private var testStringPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "text.quote", title: "Test String", color: .purple)
            
            FocusableTextEditor(text: $vm.testString)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .font(.system(.body, design: .monospaced))

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Examples")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text("Pattern: \\d+ matches: 123, 456")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Pattern: [a-z]+ matches: hello, world")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
        private var resultsPane: some View {
    
            ScrollView {
    
                VStack(alignment: .leading, spacing: 12) {
    
                    sectionHeader(icon: "list.bullet", title: "Results", color: .green)
    
                    
    
                    if let result = vm.result {
    
                        if result.hasMatches {
    
                            matchesList(result)
    
                        } else {
    
                            noMatchesView
    
                        }
    
                    } else {
    
                        emptyStateView
    
                    }
    
                }
    
                .padding()
    
            }
    
        }
    
        
    
        @ViewBuilder
    
        private func matchesList(_ result: RegExpTesterService.TestResult) -> some View {
    
            HStack {
    
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
    
                Text("\(result.matchCount) match\(result.matchCount == 1 ? "" : "es") found")
    
                    .font(.subheadline.weight(.semibold))
    
                    .foregroundStyle(.green)
    
            }
    
            .padding(.bottom, 4)
    
            
    
            ForEach(Array(result.matches.enumerated()), id: \.offset) { index, match in
    
                matchRow(index: index, match: match)
    
            }
    
        }
    
        
    
        @ViewBuilder
    
        private func matchRow(index: Int, match: RegExpTesterService.Match) -> some View {
    
            VStack(alignment: .leading, spacing: 6) {
    
                HStack {
    
                    Text("Match \(index + 1)")
    
                        .font(.caption.weight(.semibold))
    
                        .foregroundStyle(.secondary)
    
                    Spacer()
    
                    Text("Range: \(match.range.lowerBound)-\(match.range.upperBound)")
    
                        .font(.caption)
    
                        .foregroundStyle(.tertiary)
    
                }
    
                
    
                Text(match.value)
    
                    .font(.system(.body, design: .monospaced))
    
                    .padding(8)
    
                    .frame(maxWidth: .infinity, alignment: .leading)
    
                    .background(Color.green.opacity(0.1))
    
                    .cornerRadius(6)
    
                
    
                if !match.groups.isEmpty {
    
                    captureGroups(match.groups)
    
                }
    
            }
    
            .padding(8)
    
            .background(Color.secondary.opacity(0.05))
    
            .cornerRadius(8)
    
        }
    
        
    
        @ViewBuilder
    
        private func captureGroups(_ groups: [String]) -> some View {
    
            VStack(alignment: .leading, spacing: 4) {
    
                Text("Capture Groups:")
    
                    .font(.caption.weight(.medium))
    
                    .foregroundStyle(.secondary)
    
                
    
                ForEach(Array(groups.enumerated()), id: \.offset) { groupIndex, group in
    
                    if !group.isEmpty {
    
                        HStack {
    
                            Text("#\(groupIndex + 1)")
    
                                .font(.system(.caption, design: .monospaced))
    
                                .foregroundStyle(.secondary)
    
                                .frame(width: 24)
    
                            
    
                            Text(group)
    
                                .font(.system(.caption, design: .monospaced))
    
                                .padding(4)
    
                                .background(Color.blue.opacity(0.1))
    
                                .cornerRadius(4)
    
                        }
    
                    }
    
                }
    
            }
    
            .padding(.top, 4)
    
        }
    
        
    
        private var noMatchesView: some View {
    
            VStack(spacing: 12) {
    
                Image(systemName: "xmark.circle")
    
                    .font(.system(size: 32))
    
                    .foregroundStyle(.orange)
    
                Text("No matches found")
    
                    .font(.subheadline)
    
                    .foregroundStyle(.secondary)
    
            }
    
            .frame(maxWidth: .infinity)
        .padding(20)
    
            .background(Color.orange.opacity(0.05))
    
            .cornerRadius(8)
    
        }
    
        
    
        private var emptyStateView: some View {
    
            VStack(spacing: 12) {
    
                Image(systemName: "asterisk.circle")
    
                    .font(.system(size: 48))
    
                    .foregroundStyle(.secondary)
    
                Text("Enter a pattern and test string")
    
                    .font(.subheadline)
    
                    .foregroundStyle(.secondary)
    
            }
    
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    
            .padding(.top, 40)
    
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

@MainActor
final class RegExpTesterViewModel: ObservableObject {
    @Published var pattern = ""
    @Published var testString = ""
    @Published var caseInsensitive = false
    @Published var result: RegExpTesterService.TestResult?
    @Published var errorMessage: String?
    
    private let service = RegExpTesterService()
    
    func test() {
        errorMessage = nil
        result = nil
        guard !pattern.isEmpty, !testString.isEmpty else { return }
        
        do {
            result = try service.test(pattern: pattern, in: testString, caseSensitive: !caseInsensitive)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadPattern(_ pattern: String) {
        self.pattern = pattern
    }
    
    func clear() {
        pattern = ""
        testString = ""
        result = nil
        errorMessage = nil
    }
}
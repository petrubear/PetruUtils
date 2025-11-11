import SwiftUI
import Combine

struct RegExpTesterView: View {
    @StateObject private var vm = RegExpTesterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            VStack(spacing: 0) {
                patternSection
                Divider()
                HSplitView {
                    testStringSection
                    resultsSection
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack {
            Text("RegExp Tester").font(.headline)
            Spacer()
            
            Menu("Common Patterns") {
                ForEach(RegExpTesterService.commonPatterns, id: \.name) { pattern in
                    Button(pattern.name) { vm.loadPattern(pattern.pattern) }
                }
            }
            
            Toggle("Case Insensitive", isOn: $vm.caseInsensitive)
            Button("Test") { vm.test() }.keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Regular Expression Pattern").font(.headline)
            TextField("Enter regex pattern, e.g., \\d+", text: $vm.pattern)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
            
            if let error = vm.errorMessage {
                Text(error).foregroundStyle(.red).font(.callout)
            }
        }
        .padding()
    }
    
    private var testStringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test String").font(.headline)
            FocusableTextEditor(text: $vm.testString)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
        .padding()
    }
    
    private var resultsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Results").font(.headline)
                
                if let result = vm.result {
                    if result.hasMatches {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("\(result.matchCount) match\(result.matchCount == 1 ? "" : "es") found")
                                .font(.subheadline.weight(.semibold))
                        }
                        
                        ForEach(Array(result.matches.enumerated()), id: \.offset) { index, match in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Match \(index + 1)").font(.subheadline.weight(.semibold))
                                Text(match.value)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                
                                if !match.groups.isEmpty {
                                    Text("Groups:").font(.caption.weight(.semibold))
                                    ForEach(Array(match.groups.enumerated()), id: \.offset) { groupIndex, group in
                                        if !group.isEmpty {
                                            HStack {
                                                Text("Group \(groupIndex + 1):").font(.caption)
                                                Text(group)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .padding(4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.orange)
                            Text("No matches found").font(.subheadline)
                        }
                    }
                } else {
                    Text("Enter a pattern and test string, then click Test")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
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

#Preview { RegExpTesterView() }

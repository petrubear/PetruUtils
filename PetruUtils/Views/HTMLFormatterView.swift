import SwiftUI
import Combine

struct HTMLFormatterView: View {
    @StateObject private var vm = HTMLFormatterViewModel()
    
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
        HStack {
            Text("HTML Formatter").font(.headline)
            Spacer()
            Picker("Indent", selection: $vm.indentStyle) {
                ForEach(HTMLFormatterService.IndentStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .frame(width: 120)
            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input").font(.headline)
                Spacer()
                Text("\(vm.input.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            FocusableTextEditor(text: $vm.input)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output").font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            
            if let errorMessage = vm.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Error")
                            .font(.headline)
                    }
                    Text(errorMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView {
                    Text(vm.output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        .padding()
    }
}

@MainActor
final class HTMLFormatterViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var indentStyle: HTMLFormatterService.IndentStyle = .twoSpaces
    
    private let service = HTMLFormatterService()
    
    func format() {
        errorMessage = nil
        
        do {
            output = try service.format(input, indentStyle: indentStyle)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func minify() {
        errorMessage = nil
        
        do {
            output = try service.minify(input)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }
    
    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}

#Preview { HTMLFormatterView() }

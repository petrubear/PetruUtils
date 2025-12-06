import SwiftUI
import Combine

struct JSONCSVView: View {
    @StateObject private var vm = JSONCSVViewModel()
    
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
            Text("JSON ↔ CSV Converter").font(.headline)
            Spacer()
            
            Button("Convert") { vm.convert() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: vm.mode ? "curlybraces" : "tablecells", title: vm.mode ? "Input JSON" : "Input CSV", color: .blue)
                
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
                        Text("Mode")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.mode) {
                            Text("JSON → CSV").tag(true)
                            Text("CSV → JSON").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Delimiter")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.delimiter) {
                            Text("Comma (,)").tag(",")
                            Text("Semicolon (;)").tag(";")
                            Text("Tab (\t)").tag("\t")
                        }
                        .frame(width: 120)
                        .labelsHidden()
                    }
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
                    if vm.mode {
                        Text(#"[{"name": "John", "age": 30}]"#)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("name,age\nJohn,30")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
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
                Text(vm.mode ? "Output CSV" : "Output JSON")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if !vm.output.isEmpty {
                ScrollView {
                    SyntaxHighlightedText(text: vm.output, language: vm.mode ? .plain : .json)
                        .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Convert between JSON and CSV")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

@MainActor
final class JSONCSVViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var mode = true
    @Published var delimiter = ","
    @Published var errorMessage: String?
    private let service = JSONCSVService()
    
    func convert() {
        errorMessage = nil
        output = ""
        guard !input.isEmpty else { return }
        do {
            output = mode ? try service.jsonToCSV(input, delimiter: delimiter) : try service.csvToJSON(input, delimiter: delimiter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func clear() { input = ""; output = ""; errorMessage = nil }
    
    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}
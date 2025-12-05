//
//  URLView.swift
//  PetruUtils
//
//  Created by Agent on 11/7/25.
//

import SwiftUI
import Combine

// MARK: - URL View Model

@MainActor
class URLViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: ProcessMode = .encode
    @Published var componentType: URLComponentType = .queryParameter
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let service = URLService()
    
    enum ProcessMode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
    }
    
    // MARK: - Actions
    
    func process() {
        errorMessage = nil
        isValid = false
        
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encode(input, type: componentType)
                isValid = true
            case .decode:
                output = try service.decode(input, type: componentType)
                isValid = true
            }
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
    
    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    func autoDetect() {
        // Auto-detect if input is encoded
        if service.isURLEncoded(input) || service.isFormEncoded(input) {
            mode = .decode
        } else {
            mode = .encode
        }
    }
    
    // MARK: - Computed Properties
    
    var inputCharCount: Int {
        input.count
    }
    
    var outputCharCount: Int {
        output.count
    }
    
    var componentTypeName: String {
        switch componentType {
        case .fullURL:
            return "Full URL"
        case .queryParameter:
            return "Query Parameter"
        case .pathSegment:
            return "Path Segment"
        case .formData:
            return "Form Data"
        }
    }
}

// MARK: - URL View

struct URLView: View {
    @StateObject private var viewModel = URLViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main content
            HSplitView {
                // Input pane
                inputPane
                
                // Output pane
                outputPane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("URL Encoder/Decoder")
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 16) {
            // Mode selector
            Picker("Mode", selection: $viewModel.mode) {
                ForEach(URLViewModel.ProcessMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .onChange(of: viewModel.mode) { _, _ in
                viewModel.process()
            }
            
            Divider()
                .frame(height: 20)
            
            // Component type selector
            Menu {
                Button("Full URL") {
                    viewModel.componentType = .fullURL
                    viewModel.process()
                }
                Button("Query Parameter") {
                    viewModel.componentType = .queryParameter
                    viewModel.process()
                }
                Button("Path Segment") {
                    viewModel.componentType = .pathSegment
                    viewModel.process()
                }
                Button("Form Data") {
                    viewModel.componentType = .formData
                    viewModel.process()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Type:")
                        .foregroundColor(.secondary)
                    Text(viewModel.componentTypeName)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Actions
            Button("Auto-Detect") {
                viewModel.autoDetect()
                viewModel.process()
            }
            .keyboardShortcut("d", modifiers: .command)
            
            Button("Process") {
                viewModel.process()
            }
            .keyboardShortcut(.return, modifiers: .command)
            
            Button("Clear") {
                viewModel.clear()
            }
            .keyboardShortcut("k", modifiers: .command)
        }
        .padding(12)
    }
    
    // MARK: - Input Pane

    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Input label
            HStack {
                Text("Input")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.inputCharCount) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Input editor
            FocusableTextEditor(text: $viewModel.input)
                .onChange(of: viewModel.input) { _, _ in
                    viewModel.process()
                }
            .padding(.horizontal, 12)

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                Text("Examples:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("Encode: Hello World → Hello%20World")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Decode: price%3D100%26qty%3D5 → price=100&qty=5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 300)
    }
    
    // MARK: - Output Pane
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Output label
            HStack {
                Text("Output")
                    .font(.headline)
                
                if viewModel.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                if let error = viewModel.errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if !viewModel.output.isEmpty {
                    Button(action: viewModel.copyOutput) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.caption)
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
                
                Text("\(viewModel.outputCharCount) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // Output display
            CodeBlock(text: viewModel.output)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 300)
    }
}

// MARK: - Preview


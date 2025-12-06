import SwiftUI
import Combine

struct CSSFormatterView: View {
    @StateObject private var vm = CSSFormatterViewModel()

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
            Text("CSS Formatter").font(.headline)
            Spacer()

            if vm.inputFormat != .css {
                Button("Convert") { vm.convert() }.keyboardShortcut("t", modifiers: [.command])
            }
            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Prefix") { vm.addPrefixes() }.keyboardShortcut("p", modifiers: [.command])
            Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "paintbrush", title: "Input", color: .blue)

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
                        Text("Input Format")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.inputFormat) {
                            ForEach(CSSFormatterService.InputFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .frame(width: 100)
                        .labelsHidden()
                    }

                    Divider()

                    HStack {
                        Text("Indentation")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.indentStyle) {
                            ForEach(CSSFormatterService.IndentStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .frame(width: 100)
                        .labelsHidden()
                    }

                    Divider()

                    Toggle("Sort Properties", isOn: $vm.sortProperties)
                        .toggleStyle(.switch)

                    Divider()

                    Toggle("Auto-prefix on Format", isOn: $vm.autoPrefixOnFormat)
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Examples")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CSS:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(".container{display:flex;}")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("SCSS:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("$color: #333;\n.btn { color: $color; }")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LESS:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("@color: #333;\n.btn { color: @color; }")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(4)

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
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if let validationMessage = vm.validationMessage {
                HStack(spacing: 8) {
                    Image(systemName: vm.validationIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(vm.validationIsValid ? .green : .red)
                    
                    Text(validationMessage)
                        .foregroundStyle(vm.validationIsValid ? .green : .red)
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(vm.validationIsValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            }
            
            if !vm.output.isEmpty {
                ScrollView {
                    SyntaxHighlightedText(text: vm.output, language: .css)
                        .padding(8)
                }
            } else if vm.validationMessage == nil {
                VStack(spacing: 12) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Format, minify, or validate CSS")
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
final class CSSFormatterViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var validationMessage: String?
    @Published var validationIsValid = false
    @Published var indentStyle: CSSFormatterService.IndentStyle = .twoSpaces
    @Published var sortProperties = false
    @Published var inputFormat: CSSFormatterService.InputFormat = .css
    @Published var autoPrefixOnFormat = false

    private let service = CSSFormatterService()

    func format() {
        errorMessage = nil
        validationMessage = nil

        do {
            var css = input

            // Convert from SCSS/LESS if needed
            if inputFormat == .scss {
                css = try service.convertSCSSToCSS(css)
            } else if inputFormat == .less {
                css = try service.convertLESSToCSS(css)
            }

            // Format the CSS
            css = try service.format(css, indentStyle: indentStyle, sortProperties: sortProperties)

            // Add vendor prefixes if enabled
            if autoPrefixOnFormat {
                css = try service.addVendorPrefixes(css)
                // Re-format after prefixing
                css = try service.format(css, indentStyle: indentStyle, sortProperties: sortProperties)
            }

            output = css
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func minify() {
        errorMessage = nil
        validationMessage = nil

        do {
            var css = input

            // Convert from SCSS/LESS if needed
            if inputFormat == .scss {
                css = try service.convertSCSSToCSS(css)
            } else if inputFormat == .less {
                css = try service.convertLESSToCSS(css)
            }

            output = try service.minify(css)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func convert() {
        errorMessage = nil
        validationMessage = nil

        do {
            switch inputFormat {
            case .scss:
                output = try service.convertSCSSToCSS(input)
                output = try service.format(output, indentStyle: indentStyle, sortProperties: sortProperties)
            case .less:
                output = try service.convertLESSToCSS(input)
                output = try service.format(output, indentStyle: indentStyle, sortProperties: sortProperties)
            case .css:
                output = input
            }
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func addPrefixes() {
        errorMessage = nil
        validationMessage = nil

        do {
            var css = input

            // Convert from SCSS/LESS if needed
            if inputFormat == .scss {
                css = try service.convertSCSSToCSS(css)
            } else if inputFormat == .less {
                css = try service.convertLESSToCSS(css)
            }

            output = try service.addVendorPrefixes(css)
            // Format the output
            output = try service.format(output, indentStyle: indentStyle, sortProperties: sortProperties)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func validate() {
        errorMessage = nil
        output = ""

        var css = input

        // Convert from SCSS/LESS if needed before validating
        if inputFormat == .scss {
            do {
                css = try service.convertSCSSToCSS(css)
            } catch {
                validationMessage = "SCSS conversion failed: \(error.localizedDescription)"
                validationIsValid = false
                return
            }
        } else if inputFormat == .less {
            do {
                css = try service.convertLESSToCSS(css)
            } catch {
                validationMessage = "LESS conversion failed: \(error.localizedDescription)"
                validationIsValid = false
                return
            }
        }

        let result = service.validate(css)
        validationMessage = result.message
        validationIsValid = result.isValid
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        validationMessage = nil
    }

    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}
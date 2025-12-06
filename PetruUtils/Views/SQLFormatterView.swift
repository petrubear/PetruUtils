import SwiftUI
import Combine

struct SQLFormatterView: View {
    @StateObject private var vm = SQLFormatterViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "SQL Formatter",
            inputTitle: "Input SQL",
            outputTitle: "Output",
            inputIcon: "cylinder",
            outputIcon: "cylinder.split.1x2",
            toolbarContent: {
                HStack(spacing: 12) {
                    Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
                    Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
                    Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
                }
            },
            configContent: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Indentation")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.indentStyle) {
                            ForEach(SQLFormatterService.IndentStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .frame(width: 120)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    Toggle("Uppercase Keywords", isOn: $vm.uppercaseKeywords)
                        .toggleStyle(.switch)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            },
            helpContent: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("select id,name from users where active=1 order by name")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            },
            inputFooter: {
                HStack {
                    if !vm.input.isEmpty {
                        Text("\(vm.input.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            },
            outputFooter: {
                HStack {
                    if let validationMessage = vm.validationMessage {
                        HStack(spacing: 4) {
                            Image(systemName: vm.validationIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(vm.validationIsValid ? .green : .red)
                            
                            Text(validationMessage)
                                .foregroundStyle(vm.validationIsValid ? .green : .red)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(vm.validationIsValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if !vm.output.isEmpty {
                        Text("\(vm.output.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 8)
                    }
                }
            }
        )
    }
}

@MainActor
final class SQLFormatterViewModel: TextToolViewModel {
    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    @Published var validationMessage: String?
    @Published var validationIsValid = false
    @Published var indentStyle: SQLFormatterService.IndentStyle = .twoSpaces
    @Published var uppercaseKeywords = true
    
    private let service = SQLFormatterService()
    
    func process() {
        format()
    }
    
    func format() {
        errorMessage = nil
        validationMessage = nil
        isValid = false
        
        do {
            output = try service.format(input, indentStyle: indentStyle, uppercaseKeywords: uppercaseKeywords)
            isValid = true
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func minify() {
        errorMessage = nil
        validationMessage = nil
        isValid = false
        
        do {
            output = try service.minify(input)
            isValid = true
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func validate() {
        errorMessage = nil
        output = ""
        isValid = false
        
        let result = service.validate(input)
        validationMessage = result.message
        validationIsValid = result.isValid
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        validationMessage = nil
        isValid = false
    }
    
    var outputLanguage: CodeLanguage { .sql }
}
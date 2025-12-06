import SwiftUI

struct GenericTextToolView<VM: TextToolViewModel, ToolbarContent: View, ConfigContent: View, HelpContent: View, InputFooter: View, OutputFooter: View>: View {
    @ObservedObject var vm: VM
    let title: String
    let inputTitle: String
    let outputTitle: String
    let inputIcon: String
    let outputIcon: String
    
    @ViewBuilder let toolbarContent: () -> ToolbarContent
    @ViewBuilder let configContent: () -> ConfigContent
    @ViewBuilder let helpContent: () -> HelpContent
    @ViewBuilder let inputFooter: () -> InputFooter
    @ViewBuilder let outputFooter: () -> OutputFooter
    
    init(vm: VM,
         title: String,
         inputTitle: String = "Input",
         outputTitle: String = "Output",
         inputIcon: String = "text.alignleft",
         outputIcon: String = "text.alignleft",
         @ViewBuilder toolbarContent: @escaping () -> ToolbarContent,
         @ViewBuilder configContent: @escaping () -> ConfigContent,
         @ViewBuilder helpContent: @escaping () -> HelpContent,
         @ViewBuilder inputFooter: @escaping () -> InputFooter,
         @ViewBuilder outputFooter: @escaping () -> OutputFooter) {
        self.vm = vm
        self.title = title
        self.inputTitle = inputTitle
        self.outputTitle = outputTitle
        self.inputIcon = inputIcon
        self.outputIcon = outputIcon
        self.toolbarContent = toolbarContent
        self.configContent = configContent
        self.helpContent = helpContent
        self.inputFooter = inputFooter
        self.outputFooter = outputFooter
    }
    
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
            Text(title)
                .font(.headline)
            
            Spacer()
            
            toolbarContent()
            
            Button("Process") { vm.process() }
                .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(icon: inputIcon, title: inputTitle, color: .blue)
                    
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200, maxHeight: .infinity)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .background(.background)
                    
                    inputFooter()
                    
                    // Configuration Section
                    configContent()

                    // Error Message
                    if let error = vm.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.callout)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Help/Extra Section
                    helpContent()
                }
                .padding()
            }
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(outputTitle)
                    .font(.headline)
                Spacer()
                outputFooter()
                if !vm.output.isEmpty {
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if !vm.output.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                         sectionHeader(icon: outputIcon, 
                                      title: "Result", 
                                      color: .green)
                        Spacer()
                        if vm.isValid {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Valid")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding([.top, .horizontal])
                    .padding(.bottom, 8)
                    
                    CodeBlock(text: vm.output, language: vm.outputLanguage)
                        .frame(maxHeight: .infinity)
                        .padding([.horizontal, .bottom])
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: outputIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Result will appear here")
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

// Default Input/Output Footer (Character Count)

extension GenericTextToolView where InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM,

         title: String,

         inputTitle: String = "Input",

         outputTitle: String = "Output",

         inputIcon: String = "text.alignleft",

         outputIcon: String = "text.alignleft",

         @ViewBuilder toolbarContent: @escaping () -> ToolbarContent,

         @ViewBuilder configContent: @escaping () -> ConfigContent,

         @ViewBuilder helpContent: @escaping () -> HelpContent) {

        self.init(vm: vm,

                  title: title,

                  inputTitle: inputTitle,

                  outputTitle: outputTitle,

                  inputIcon: inputIcon,

                  outputIcon: outputIcon,

                  toolbarContent: toolbarContent,

                  configContent: configContent,

                  helpContent: helpContent,

                  inputFooter: {

            AnyView(HStack {

                if !vm.input.isEmpty {

                    Text("\(vm.inputCharCount) characters")

                        .foregroundStyle(.secondary)

                        .font(.caption)

                }

                Spacer()

            })

        },

                  outputFooter: {

            AnyView(Group {

                if !vm.output.isEmpty {

                    Text("\(vm.outputCharCount) characters")

                        .foregroundStyle(.secondary)

                        .font(.caption)

                        .padding(.trailing, 8)

                }

            })

        })

    }

}



// Extension for convenience init when views are empty

extension GenericTextToolView where ToolbarContent == EmptyView, ConfigContent == EmptyView, HelpContent == EmptyView, InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM, title: String) {

        self.init(vm: vm, 

                  title: title, 

                  toolbarContent: { EmptyView() }, 

                  configContent: { EmptyView() }, 

                  helpContent: { EmptyView() })

    }

}



extension GenericTextToolView where ToolbarContent == EmptyView, InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM, 

         title: String,

         @ViewBuilder configContent: @escaping () -> ConfigContent,

         @ViewBuilder helpContent: @escaping () -> HelpContent) {

        self.init(vm: vm, 

                  title: title, 

                  toolbarContent: { EmptyView() }, 

                  configContent: configContent, 

                  helpContent: helpContent)

    }

}

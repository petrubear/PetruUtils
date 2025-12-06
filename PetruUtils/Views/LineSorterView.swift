import SwiftUI
import Combine

struct LineSorterView: View {
    @StateObject private var vm = LineSorterViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Line Sorter",
            inputTitle: "Input Lines",
            outputTitle: "Output",
            inputIcon: "text.alignleft",
            outputIcon: "text.alignleft",
            toolbarContent: {
                HStack(spacing: 12) {
                    Button("Sort") { vm.sort() }
                        .keyboardShortcut(.return, modifiers: [.command])
                    Button("Reverse") { vm.reverse() }
                    Button("Shuffle") { vm.shuffle() }
                }
            },
            configContent: {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.purple)
                        Text("Configuration")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sort Order")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $vm.sortOrder) {
                                Text("Ascending").tag(LineSorterService.SortOrder.ascending)
                                Text("Descending").tag(LineSorterService.SortOrder.descending)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                            .labelsHidden()
                        }
                        
                        Divider()
                        
                        Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                            .toggleStyle(.switch)
                        
                        Divider()
                        
                        Toggle("Natural Sort", isOn: $vm.naturalSort)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            },
            helpContent: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Usage")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("Enter one item per line. Sort alphabetically, reverse, or shuffle.")
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
                        Text("\(vm.inputLineCount) lines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            },
            outputFooter: {
                if !vm.output.isEmpty {
                    Text("\(vm.outputLineCount) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
            }
        )
    }
}

@MainActor
final class LineSorterViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    @Published var sortOrder: LineSorterService.SortOrder = .ascending
    @Published var caseSensitive: Bool = true
    @Published var naturalSort: Bool = false
    
    private let service = LineSorterService()
    
    var inputLineCount: Int {
        service.lineCount(input)
    }
    
    var outputLineCount: Int {
        service.lineCount(output)
    }
    
    func process() {
        sort()
    }
    
    func sort() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            output = ""
            isValid = false
            return
        }
        
        output = service.sortLines(input, order: sortOrder, caseSensitive: caseSensitive, naturalSort: naturalSort)
        isValid = true
    }
    
    func reverse() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            output = ""
            isValid = false
            return
        }
        
        output = service.reverseLines(input)
        isValid = true
    }
    
    func shuffle() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            output = ""
            isValid = false
            return
        }
        
        output = service.shuffleLines(input)
        isValid = true
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
}
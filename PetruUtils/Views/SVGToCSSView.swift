import SwiftUI
import Combine
import AppKit

struct SVGToCSSView: View {
    @StateObject private var viewModel = SVGToCSSViewModel()

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
            Text("SVG → CSS Converter").font(.headline)
            Spacer()

            Toggle("Optimize", isOn: $viewModel.optimize)
                .toggleStyle(.checkbox)
                .help("Optimize SVG by removing metadata and whitespace")

            Picker("Format", selection: $viewModel.selectedFormat) {
                Text("background-image").tag(SVGToCSSService.OutputFormat.backgroundImage)
                Text("background").tag(SVGToCSSService.OutputFormat.backgroundProperty)
                Text("mask-image").tag(SVGToCSSService.OutputFormat.maskImage)
                Text("list-style-image").tag(SVGToCSSService.OutputFormat.listStyleImage)
                Text("border-image").tag(SVGToCSSService.OutputFormat.borderImage)
                Text("content").tag(SVGToCSSService.OutputFormat.contentProperty)
            }
            .frame(width: 200)

            Button("Convert") { viewModel.convert() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { viewModel.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SVG Code").font(.headline)
                Spacer()
                if viewModel.showPreview {
                    Button("Hide Preview") { viewModel.showPreview = false }
                } else {
                    Button("Show Preview") { viewModel.showPreview = true }
                }
            }

            FocusableTextEditor(text: $viewModel.input)
                .frame(minHeight: viewModel.showPreview ? 200 : 300)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            HStack {
                if !viewModel.input.isEmpty {
                    Text("\(viewModel.input.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            // SVG Preview
            if viewModel.showPreview {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview").font(.headline)

                    if let svgImage = viewModel.svgPreviewImage {
                        Image(nsImage: svgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .padding(8)
                            .background(
                                ZStack {
                                    // Checkerboard background to show transparency
                                    Canvas { context, size in
                                        let squareSize: CGFloat = 10
                                        for row in 0..<Int(size.height / squareSize) + 1 {
                                            for col in 0..<Int(size.width / squareSize) + 1 {
                                                if (row + col) % 2 == 0 {
                                                    let rect = CGRect(
                                                        x: CGFloat(col) * squareSize,
                                                        y: CGFloat(row) * squareSize,
                                                        width: squareSize,
                                                        height: squareSize
                                                    )
                                                    context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
                                                }
                                            }
                                        }
                                    }
                                    Color.white.opacity(0.5)
                                }
                            )
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    } else {
                        Text("Enter valid SVG to see preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .frame(alignment: .center)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let dims = viewModel.dimensions {
                        HStack(spacing: 12) {
                            if let width = dims.width {
                                Text("Width: \(width)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let height = dims.height {
                                Text("Height: \(height)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                Text("Example SVG:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("""
                <svg width="100" height="100">
                  <circle cx="50" cy="50" r="40" fill="blue"/>
                </svg>
                """)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding()
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("CSS Output").font(.headline)
                Spacer()
                if !viewModel.output.isEmpty {
                    Button {
                        viewModel.copyToClipboard()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .help("Copy CSS to clipboard (⌘⇧C)")
                }
            }

            CodeBlock(text: viewModel.output, language: .css)
                .frame(maxHeight: .infinity)

            HStack {
                if !viewModel.output.isEmpty {
                    Text("\(viewModel.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let sizeInfo = viewModel.sizeInfo {
                    Spacer()
                    Text("Data URI size: \(sizeInfo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Usage instructions
            if !viewModel.output.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usage:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.usageExample)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Spacer()
        }
        .padding()
    }
}

@MainActor
final class SVGToCSSViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var optimize: Bool = true
    @Published var selectedFormat: SVGToCSSService.OutputFormat = .backgroundImage
    @Published var showPreview: Bool = false
    @Published var svgPreviewImage: NSImage?
    @Published var dimensions: (width: String?, height: String?)?
    @Published var sizeInfo: String?

    private let service = SVGToCSSService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Auto-convert when format changes
        $selectedFormat
            .dropFirst()
            .sink { [weak self] _ in
                self?.convert()
            }
            .store(in: &cancellables)

        // Auto-convert when optimize toggle changes
        $optimize
            .dropFirst()
            .sink { [weak self] _ in
                self?.convert()
            }
            .store(in: &cancellables)

        // Update preview when input changes
        $input
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePreview()
            }
            .store(in: &cancellables)
    }

    func convert() {
        errorMessage = nil
        output = ""
        sizeInfo = nil

        guard !input.isEmpty else {
            errorMessage = "Please enter SVG code"
            return
        }

        do {
            output = try service.convertToCSS(
                svg: input,
                optimize: optimize,
                format: selectedFormat
            )

            // Calculate size info
            if let dataURIRange = output.range(of: "data:image/svg+xml,") {
                let dataURIStart = output[dataURIRange.lowerBound...]
                if let urlEnd = dataURIStart.firstIndex(of: "'") ?? dataURIStart.firstIndex(of: ")") {
                    let dataURI = String(dataURIStart[..<urlEnd])
                    let size = service.getDataURISize(dataURI)
                    sizeInfo = service.formatFileSize(size)
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func updatePreview() {
        guard !input.isEmpty, service.isValidSVG(input) else {
            svgPreviewImage = nil
            dimensions = nil
            return
        }

        // Extract dimensions
        dimensions = service.extractDimensions(from: input)

        // Try to render preview
        if let data = input.data(using: .utf8),
           let svgImage = NSImage(data: data) {
            svgPreviewImage = svgImage
        } else {
            svgPreviewImage = nil
        }
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        svgPreviewImage = nil
        dimensions = nil
        sizeInfo = nil
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }

    var usageExample: String {
        switch selectedFormat {
        case .backgroundImage:
            return """
            .element {
              /* Add the generated CSS property */
              width: 100px;
              height: 100px;
            }
            """
        case .backgroundProperty:
            return """
            .element {
              /* The SVG will fill the element */
              width: 200px;
              height: 200px;
            }
            """
        case .maskImage:
            return """
            .element {
              /* Use with background color */
              background-color: #3498db;
              width: 100px;
              height: 100px;
            }
            """
        case .listStyleImage:
            return """
            ul {
              /* Custom bullet points */
              list-style-position: inside;
            }
            """
        case .borderImage:
            return """
            .element {
              /* Decorative border */
              border: 30px solid transparent;
            }
            """
        case .contentProperty:
            return """
            .element::before {
              /* Pseudo-element content */
            }
            """
        }
    }
}

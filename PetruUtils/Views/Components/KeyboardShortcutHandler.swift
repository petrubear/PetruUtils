import SwiftUI
import AppKit

/// A view that monitors for a specific keyboard shortcut and executes an action
struct KeyboardShortcutHandler: NSViewRepresentable {
    let key: String
    let modifiers: NSEvent.ModifierFlags
    let action: () -> Void

    func makeNSView(context: Context) -> KeyboardMonitorView {
        let view = KeyboardMonitorView()
        view.key = key
        view.modifiers = modifiers
        view.action = action
        return view
    }

    func updateNSView(_ nsView: KeyboardMonitorView, context: Context) {
        nsView.key = key
        nsView.modifiers = modifiers
        nsView.action = action
    }
}

class KeyboardMonitorView: NSView {
    var key: String = ""
    var modifiers: NSEvent.ModifierFlags = []
    var action: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil && monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }

                // Check if the key matches
                let eventKey = event.charactersIgnoringModifiers?.lowercased() ?? ""
                let eventModifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])

                if eventKey == self.key.lowercased() && eventModifiers == self.modifiers {
                    self.action?()
                    return nil // Consume the event
                }

                return event
            }
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)

        if newWindow == nil, let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

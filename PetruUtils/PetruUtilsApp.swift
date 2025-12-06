//
//  PetruUtilsApp.swift
//  PetruUtils
//
//  Created by Edison Martinez on 2/10/25.
//

import SwiftUI
import Combine

// MARK: - Command Palette State

@MainActor
final class CommandPaletteState: ObservableObject {
    static let shared = CommandPaletteState()
    @Published var isPresented: Bool = false

    private init() {}

    func toggle() {
        isPresented.toggle()
    }

    func show() {
        isPresented = true
    }

    func hide() {
        isPresented = false
    }
}

@main
struct PetruUtilsApp: App {
    @StateObject private var commandPaletteState = CommandPaletteState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(commandPaletteState)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text("Preferences...")
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button(String(localized: "menu.goToTool")) {
                    commandPaletteState.show()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }

        Settings {
            PreferencesView()
        }
    }
}

//
//  ContentView.swift
//  PetruUtils
//
//  Created by Edison Martinez on 2/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Tool? = .jwt
        var body: some View {
            NavigationSplitView {
                List(Tool.allCases, selection: $selection) { Text($0.title) }
                    .navigationTitle("Tools")
            } detail: {
                switch selection {
                case .jwt: JWTView()
                //case .base64: Base64View()
                //case .qr: QRView()
                default: Text("Select a tool")
                }
            }
        }
}

#Preview {
    ContentView()
}

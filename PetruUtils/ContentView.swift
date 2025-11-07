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
            List(Tool.allCases, selection: $selection) { tool in
                Label(tool.title, systemImage: tool.iconName)
                    .tag(tool)
            }
            .navigationTitle("Tools")
        } detail: {
            switch selection {
            case .jwt:
                JWTView()
            case .base64:
                Base64View()
            case .urlEncoder:
                URLView()
            case .qr:
                PlaceholderView(toolName: "QR Code Generator")
            case .none:
                Text("Select a tool")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Placeholder view for unimplemented tools
struct PlaceholderView: View {
    let toolName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(toolName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}

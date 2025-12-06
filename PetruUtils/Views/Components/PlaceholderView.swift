import SwiftUI

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

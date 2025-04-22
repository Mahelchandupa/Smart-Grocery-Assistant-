import SwiftUI

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 70, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

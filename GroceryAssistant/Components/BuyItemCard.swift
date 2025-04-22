
import SwiftUI

struct BuyItemCard: View {
    let item: Buy
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            HStack(alignment: .top, spacing: 12) {
                // Product Image
                if let url = URL(string: item.image) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                ProgressView()
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        case .failure:
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 100, height: 100)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 100, height: 100)
                }
                
                // Product Information
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text("Qty: \(item.quantity)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.green)
                        .padding(.top, 2)
                    
                    Spacer()
                    
                    // Buy button (link to online store)
                    HStack {
                        Link(destination: URL(string: item.link) ?? URL(string: "https://google.com")!) {
                            HStack {
                                Text("Buy Online")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isExpanded.toggle()
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(12)
            
            // Expandable details section
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    Text("Product Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Display additional details
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(icon: "tag.fill", label: "Name", value: item.name)
                        DetailRow(icon: "number", label: "Quantity", value: item.quantity)
                        DetailRow(icon: "dollarsign.circle.fill", label: "Price", value: "$\(String(format: "%.2f", item.price))")
                    }
                    
                    // Full width link button to the online store
                    Link(destination: URL(string: item.link) ?? URL(string: "https://google.com")!) {
                        HStack {
                            Text("View at Online Store")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

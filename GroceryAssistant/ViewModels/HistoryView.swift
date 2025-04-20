//
//  HistoryView.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/31/25.
//

import SwiftUI

struct HistoryView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.green
                    .ignoresSafeArea(edges: .top)
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()}) {
                                Image(systemName: "arrow.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            .padding(.trailing, 8)
                        
                        Text("Nutritional Info")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 8)
                .padding(.horizontal, 16)
            }
            .frame(height: 120)
            
        }
    }
}

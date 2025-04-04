//
//  NutritionalInfoView.swift
//  GroceryAssistant
//
//  Created by sasiri rukshan nanayakkara on 3/31/25.
//

import SwiftUI

struct NutritionalInfoView: View {
    @Binding var navPath: NavigationPath
    @EnvironmentObject var authManager: AuthManager
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color.green
                    .ignoresSafeArea(edges: .top)
                VStack {
                    HStack {
                        Button(action: {
                            navPath.removeLast()}) {
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

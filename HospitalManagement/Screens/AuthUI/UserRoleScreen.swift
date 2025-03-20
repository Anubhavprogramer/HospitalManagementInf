//
//  RoleSelectionView.swift
//  HospitalManagement
//
//  Created by Nupur on 19/03/25.
//

import SwiftUI

struct UserRoleScreen: View {
    let roles = ["Patient", "Doctor", "Admin", "Super-Admin"]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Select Your Role")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Spacer()
                
                ForEach(roles, id: \.self) { role in
                    if role == "Patient" {
                        NavigationLink(destination: LoginScreen()) {
                            RoleCard(role: role)
                        }
                    } else {
                        NavigationLink(destination: RoleDetailView(role: role)) {
                            RoleCard(role: role)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Role Card
struct RoleCard: View {
    var role: String
    
    var body: some View {
        HStack {
            Text(role)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.mint)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.mint)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)  // Increased height to 100
        .background(Color.mint.opacity(0.2))
        .cornerRadius(15)
        .padding(.vertical, 10)
        .shadow(color: .mint.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Role Detail View (Destination Screen)
struct RoleDetailView: View {
    var role: String
    
    var body: some View {
        VStack {
            Text("Welcome, \(role)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.mint)
                .padding()
            
            Spacer()
        }
        .navigationTitle(role)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        UserRoleScreen()
    }
}

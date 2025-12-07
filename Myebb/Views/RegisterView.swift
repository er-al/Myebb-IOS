//
//  RegisterView.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.textPrimary)
                            Text("Start tracking your emotional rhythm")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 18) {
                            TextField("", text: $email)
                                .softFieldStyle(placeholder: "Email", icon: "envelope", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            
                            SecureField("", text: $password)
                                .softFieldStyle(placeholder: "Password", icon: "lock", text: $password)
                            
                            SecureField("", text: $confirmPassword)
                                .softFieldStyle(placeholder: "Confirm Password", icon: "lock.rotation", text: $confirmPassword)
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.moodDownRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Button(action: handleRegister) {
                                HStack {
                                    if isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ColorTheme.stemGreen)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                            .opacity(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty ? 0.6 : 1)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.textPrimary)
                }
            }
        }
        .tint(ColorTheme.stemGreen)
    }
    
    private func handleRegister() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let response = try await APIService.shared.register(email: email, password: password)
                await MainActor.run {
                    authManager.login(token: response.token, user: response.user)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "Registration failed. Please try again."
                        }
                    } else {
                        errorMessage = "Registration failed. Please try again."
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}


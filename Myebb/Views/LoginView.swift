//
//  LoginView.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite
                    .ignoresSafeArea()
                
                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 32) {
                            VStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 64, weight: .light))
                                    .foregroundColor(ColorTheme.stemGreen)
                                Text("Myebb")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(ColorTheme.textPrimary)
                                Text("Track the rhythm of your feelings")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.textSecondary)
                            }
                            
                            VStack(spacing: 20) {
                                TextField("", text: $email)
                                    .softFieldStyle(placeholder: "Email", icon: "envelope", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                
                                SecureField("", text: $password)
                                    .softFieldStyle(placeholder: "Password", icon: "lock", text: $password)
                                
                                if !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.moodDownRed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Button(action: handleLogin) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Log In")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(MoodPalette.positivePrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                                .disabled(isLoading || email.isEmpty || password.isEmpty)
                                .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1)
                                
                                Button(action: { showingRegister = true }) {
                                    Text("Create an account")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ColorTheme.stemGreen)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxWidth: 420)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                        .frame(minHeight: geo.size.height, alignment: .center)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
        }
        .tint(ColorTheme.stemGreen)
    }
    
    private func handleLogin() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let response = try await APIService.shared.login(email: email, password: password)
                await MainActor.run {
                    authManager.login(token: response.token, user: response.user)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        case .unauthorized:
                            errorMessage = "Invalid email or password"
                        default:
                            errorMessage = "Login failed. Please try again."
                        }
                    } else {
                        errorMessage = "Login failed. Please try again."
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}


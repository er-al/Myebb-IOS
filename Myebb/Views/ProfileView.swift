//
//  ProfileView.swift
//  Myebb
//
//  Created by ChatGPT on 12/7/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    @State private var name: String = ""
    @State private var avatarURL: String?
    @State private var avatarDataURL: String?
    @State private var selectedImageData: Data?
    
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var pickerItem: PhotosPickerItem?
    
    private var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentName = authManager.currentUser?.name ?? ""
        return (!trimmedName.isEmpty && trimmedName != currentName) || avatarDataURL != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    emailSection
                    nameSection
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(ColorTheme.moodDownRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.footnote)
                            .foregroundColor(ColorTheme.stemGreen)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer(minLength: 12)
                }
                .padding(24)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
            .task {
                await loadProfile()
            }
            .tint(ColorTheme.stemGreen)
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorTheme.mistGray.opacity(0.35))
                    .frame(width: 140, height: 140)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(ColorTheme.stemGreen)
                } else if let data = selectedImageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else if let urlString = avatarURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderAvatar
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                }
            }
            
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Change Photo", systemImage: "photo")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(ColorTheme.stemGreen.opacity(0.12))
                    )
            }
            .tint(ColorTheme.stemGreen)
            .onChange(of: pickerItem) { _ in
                Task { await handleImageSelection() }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Email")
                .font(.headline)
                .foregroundColor(ColorTheme.textPrimary)

            ZStack(alignment: .leading) {
                Text(authManager.currentUser?.email ?? "")
                    .foregroundColor(ColorTheme.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.mistGray.opacity(0.5), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(ColorTheme.mistGray.opacity(0.1))
                            )
                    )
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.headline)
                .foregroundColor(ColorTheme.textPrimary)

            ZStack(alignment: .leading) {
                TextField("Your name", text: $name)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.mistGray, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    )
                    .disabled(isLoading)

                if isLoading {
                    HStack {
                        ProgressView()
                            .tint(ColorTheme.stemGreen)
                            .padding(.leading, 16)
                        Text("Loading...")
                            .foregroundColor(ColorTheme.textSecondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
    }
    
    private var placeholderAvatar: some View {
        let initial = authManager.currentUser?.name?.first.map(String.init) ?? "🙂"
        return Text(initial)
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(ColorTheme.textSecondary)
            .frame(width: 140, height: 140)
            .background(ColorTheme.mistGray.opacity(0.35))
            .clipShape(Circle())
    }
    
    private func loadProfile() async {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        do {
            let user = try await APIService.shared.getProfile()
            await MainActor.run {
                name = user.name ?? ""
                avatarURL = user.avatarURL
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again."
                        authManager.logout()
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Failed to load profile."
                    }
                } else {
                    errorMessage = "Failed to load profile."
                }
            }
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        errorMessage = ""
        successMessage = ""
        
        do {
            let updatedUser = try await APIService.shared.updateProfile(
                name: name,
                avatarDataURL: avatarDataURL
            )
            
            await MainActor.run {
                authManager.updateUser(updatedUser)
                name = updatedUser.name ?? ""
                avatarURL = updatedUser.avatarURL
                avatarDataURL = nil
                isSaving = false
                successMessage = "Profile updated!"
            }
        } catch {
            await MainActor.run {
                isSaving = false
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again."
                        authManager.logout()
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Failed to update profile."
                    }
                } else {
                    errorMessage = "Failed to update profile."
                }
            }
        }
    }
    
    private func handleImageSelection() async {
        guard let item = pickerItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    selectedImageData = data
                    let contentType = item.supportedContentTypes.first
                    avatarDataURL = makeDataURL(from: data, contentType: contentType)
                    successMessage = ""
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Could not load the selected image."
            }
        }
    }
    
    private func makeDataURL(from data: Data, contentType: UTType?) -> String {
        let mime: String
        if contentType?.conforms(to: .png) == true {
            mime = "image/png"
        } else {
            mime = "image/jpeg"
        }
        return "data:\(mime);base64,\(data.base64EncodedString())"
    }
}

#Preview {
    ProfileView()
}

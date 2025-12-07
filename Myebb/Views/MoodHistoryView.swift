//
//  MoodHistoryView.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

struct MoodHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var moods: [Mood] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedMood: Mood?
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        ProgressView("Loading history...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if moods.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(ColorTheme.textSecondary)
                            Text("No state history yet")
                                .font(.headline)
                                .foregroundColor(ColorTheme.textPrimary)
                            Text("Start logging your state to see your history here")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        historyList
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.stemGreen)
                }
            }
            .task {
                await loadHistory()
            }
            .sheet(item: $selectedMood) { mood in
                MoodDetailSheet(mood: mood)
            }
        }
        .tint(ColorTheme.stemGreen)
    }
    
    @ViewBuilder
    private var historyList: some View {
        let list = List {
                            Section {
                                NavigationLink {
                                    DashboardView()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Open Insights")
                                                .font(.headline)
                                                .foregroundColor(ColorTheme.textPrimary)
                                        }
                                        Spacer()
                                        Image(systemName: "chart.bar.xaxis")
                                            .font(.footnote)
                                            .foregroundColor(ColorTheme.stemGreen)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
            Section {
                ForEach(moods) { mood in
                    HStack(spacing: 16) {
                        Image(systemName: mood.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(mood.isPositive ? MoodPalette.positivePrimary : MoodPalette.negativePrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mood.formattedDate)
                                .font(.headline)
                                .foregroundColor(ColorTheme.textPrimary)
                            if let note = mood.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(mood.isPositive ? "Up" : "Down")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(mood.isPositive ? MoodPalette.positivePrimary : MoodPalette.negativePrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    (mood.isPositive ? MoodPalette.positivePrimary : MoodPalette.negativePrimary)
                                        .opacity(0.15)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMood = mood
                    }
                }
            } header: {
                Text("Daily Log")
            }
        }
        .listStyle(PlainListStyle())
        .background(ColorTheme.lilyWhite)
        
        if #available(iOS 16.0, *) {
            list.scrollContentBackground(.hidden)
        } else {
            list
        }
    }
    
    private func loadHistory() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let history = try await APIService.shared.getMoodHistory(limit: 50)
            await MainActor.run {
                moods = history
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Failed to load history"
                    }
                } else {
                    errorMessage = "Failed to load history"
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    MoodHistoryView()
}
#endif

private struct MoodDetailSheet: View {
    let mood: Mood
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: mood.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(mood.isPositive ? MoodPalette.positivePrimary : MoodPalette.negativePrimary)
                        VStack(alignment: .leading) {
                            Text(mood.formattedDate)
                                .font(.headline)
                                .foregroundColor(ColorTheme.textPrimary)
                            Text(mood.isPositive ? "Up" : "Down")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.textSecondary)
                        if let note = mood.note, !note.isEmpty {
                            Text(note)
                                .font(.body)
                                .foregroundColor(ColorTheme.textPrimary)
                        } else {
                            Text("No description provided.")
                                .font(.body)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("State Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.stemGreen)
                }
            }
        }
    }
}

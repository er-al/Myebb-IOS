//
//  MoodLoggingView.swift
//  Nari
//
//  Created by Eric Al on 11/17/25.
//

import SwiftUI

struct MoodLoggingView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var todayMood: Mood?
    @State private var isLoading = false
    @State private var isLogging = false
    @State private var errorMessage = ""
    @State private var showingHistory = false
    @State private var showingInsights = false
    @State private var moodNote = ""
    @State private var moodLevel = 0 // -5 to 5, 0 = neutral
    @State private var showEntrySheet = false
    @State private var pendingEntryLevel: Int?
    @State private var previousMoodLevel = 0
    @State private var shouldRestoreMoodLevelOnDismiss = false
    
    private let defaultMoodLevel = 3
    
    private var hasLoggedToday: Bool {
        todayMood != nil
    }

    private var isDailyLimitEnforced: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    private var limitReached: Bool {
        hasLoggedToday && isDailyLimitEnforced
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            dateCard
                            statusCard
                            moodButtons
                            
                            if isLogging {
                                ProgressView("Logging state...")
                                    .padding()
                            }
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.moodDownRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(24)
                    }
                    
                    viewHistoryButton
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        .background(ColorTheme.lilyWhite.opacity(0.95))
                }
            }
            .navigationTitle("Myebb")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Logout", systemImage: "arrow.right.square") {
                            authManager.logout()
                        }
                        Button("Open Insights", systemImage: "chart.bar") {
                            showingInsights = true
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundColor(ColorTheme.stemGreen)
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                MoodHistoryView()
            }
            .sheet(isPresented: $showingInsights) {
                DashboardView()
            }
            .sheet(isPresented: $showEntrySheet) {
                entrySheet
            }
            .task {
                await loadTodayMood()
            }
            .onChange(of: showEntrySheet) { isPresented in
                if !isPresented && shouldRestoreMoodLevelOnDismiss {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        moodLevel = previousMoodLevel
                    }
                    shouldRestoreMoodLevelOnDismiss = false
                    pendingEntryLevel = nil
                }
            }
        }
        .tint(ColorTheme.stemGreen)
    }
    
    private var dateCard: some View {
        VStack(spacing: 4) {
            Text("Today")
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
            Text(dateFormatter.string(from: Date()))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var statusCard: some View {
        Group {
            if todayMood != nil {
                EmptyView()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ColorTheme.stemGreen)
                    Text("No state logged yet today")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)
                    Text("Slide the thermometer to capture how you feel.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var moodButtons: some View {
        Group {
            if limitReached {
                VStack(spacing: 12) {
                    if let mood = todayMood {
                        Image(systemName: mood.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 128))
                            .foregroundColor(mood.isPositive ? MoodPalette.positivePrimary : MoodPalette.negativePrimary)
                    }
                    Text("State saved for today")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("You can add a note below or come back tomorrow.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(ColorTheme.mistGray.opacity(0.4))
                )
                .frame(maxWidth: .infinity)
                .frame(minHeight: 280, alignment: .center)
            } else {
                let controlDisabled = isLogging || isLoading
                
                VStack(spacing: 20) {
                    ThermometerControl(
                        level: $moodLevel,
                        disabled: controlDisabled,
                        onCommit: handleThermometerCommit,
                        onDoubleTap: handleHandleDoubleTap
                    )
                        .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 6) {
                        Text(moodLevelLabel)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(moodLevelColor)
                            .animation(.easeInOut(duration: 0.2), value: moodLevel)
                        
                        Text("Drag up for brighter energy, down for heavier moods.")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 10)
                )
            }
        }
    }
    
    private var viewHistoryButton: some View {
        Button(action: { showingHistory = true }) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("View History")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ColorTheme.pebbleGray.opacity(0.6), lineWidth: 1)
            )
        }
        .foregroundColor(ColorTheme.textPrimary)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var saveDisabled: Bool {
        pendingEntryLevel == nil || isLogging || isLoading || limitReached
    }
    
    private var moodLevelLabel: String {
        switch moodLevel {
        case 1...5:
            return "Feeling Up"
        case -5...(-1):
            return "Feeling Down"
        default:
            return "Equanimity"
        }
    }
    
    private var moodLevelColor: Color {
        switch moodLevel {
        case 1...5:
            return MoodPalette.positivePrimary
        case -5...(-1):
            return MoodPalette.negativePrimary
        default:
            return ColorTheme.textSecondary
        }
    }
    
    private var entrySheet: some View {
        NavigationView {
            ZStack {
                ColorTheme.lilyWhite.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why do you feel this way?")
                            .font(.headline)
                            .foregroundColor(ColorTheme.textPrimary)
                        Text("Optional reflection to remember this moment.")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if moodNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Write a few words...")
                                .foregroundColor(ColorTheme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 10)
                        }
                        TextEditor(text: $moodNote)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(ColorTheme.mistGray, lineWidth: 1)
                            )
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                    
                    Button(action: savePendingMood) {
                        HStack {
                            if isLogging {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Submit Entry for Today")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(saveDisabled || isLogging ? ColorTheme.pebbleGray.opacity(0.6) : ColorTheme.stemGreen)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(saveDisabled || isLogging)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Reflect & Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showEntrySheet = false
                    }
                }
            }
        }
    }
    
    private func handleThermometerCommit(_ level: Int) {
        guard level != 0, !limitReached else { return }
        pendingEntryLevel = level
        shouldRestoreMoodLevelOnDismiss = false
        showEntrySheet = true
    }
    
    private func handleHandleDoubleTap() {
        guard !limitReached else { return }
        previousMoodLevel = moodLevel
        pendingEntryLevel = defaultMoodLevel
        shouldRestoreMoodLevelOnDismiss = true
        withAnimation(.easeInOut(duration: 0.2)) {
            moodLevel = defaultMoodLevel
        }
        showEntrySheet = true
    }
    
    private func loadTodayMood() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let mood = try await APIService.shared.getTodayMood()
            await MainActor.run {
                todayMood = mood
                moodLevel = 0
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
                        let normalized = message.lowercased()
                        if normalized.contains("state not found") || normalized.contains("mood not found") {
                            todayMood = nil
                            errorMessage = ""
                        } else {
                            errorMessage = message
                        }
                    default:
                        errorMessage = "Failed to load today's state"
                    }
                } else {
                    errorMessage = "Failed to load today's state"
                }
            }
        }
    }
    
    private func logMood(state: Int, intensity: Int) {
        isLogging = true
        errorMessage = ""
        
        Task {
            do {
                let trimmedNote = moodNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let noteParam = trimmedNote.isEmpty ? nil : trimmedNote
                let mood = try await APIService.shared.logMood(state: state, intensity: intensity, date: nil, note: noteParam)
                await MainActor.run {
                    todayMood = mood
                    isLogging = false
                    moodNote = ""
                    pendingEntryLevel = nil
                    shouldRestoreMoodLevelOnDismiss = false
                    showEntrySheet = false
                    moodLevel = 0
                }
            } catch {
                await MainActor.run {
                    isLogging = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "Failed to log state. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to log state. Please try again."
                    }
                }
            }
        }
    }
    
    private func savePendingMood() {
        guard let level = pendingEntryLevel else { return }
        let state = level > 0 ? 1 : 0
        let intensity = min(5, max(1, abs(level)))
        logMood(state: state, intensity: intensity)
    }
}

private struct ThermometerControl: View {
    @Binding var level: Int
    let disabled: Bool
    let onCommit: (Int) -> Void
    let onDoubleTap: () -> Void
    
    private let maxLevel = 5
    private let minLevel = -5
    private let trackCornerRadius: CGFloat = 36
    @State private var wavePhase: CGFloat = 0
    @State private var dragActive = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
            .fill(trackGradient)
            .frame(width: 150, height: 340)
            .overlay(
                RoundedRectangle(cornerRadius: trackCornerRadius)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .overlay(
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        fillOverlay(in: size)
                        tickMarks(in: size)
                        handle(in: size)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: trackCornerRadius))
                    .contentShape(RoundedRectangle(cornerRadius: trackCornerRadius))
                    .gesture(dragGesture(in: size))
                }
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .opacity(disabled ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.2), value: level)
    }
    
    private var trackGradient: LinearGradient {
        LinearGradient(
            colors: [
                MoodPalette.positivePrimary.opacity(0.4),
                ColorTheme.mistGray.opacity(0.35),
                MoodPalette.negativePrimary.opacity(0.4)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    @ViewBuilder
    private func fillOverlay(in size: CGSize) -> some View {
        let innerWidth = size.width
        let innerHeight = size.height
        let halfHeight = innerHeight / 2
        
        ZStack {
            if level > 0 {
                let fraction = CGFloat(level) / CGFloat(maxLevel)
                let height = max(halfHeight * fraction, 4)
                positiveFillGradient
                    .frame(width: innerWidth, height: height)
                    .offset(y: -height / 2)
                    .animation(.easeInOut(duration: 0.2), value: level)
                    .overlay(
                        dragActive && height > 12
                        ? waveOverlay(width: innerWidth, height: height, alignTop: true, intensity: fraction)
                        : nil
                    )
            }
            
            if level < 0 {
                let fraction = CGFloat(abs(level)) / CGFloat(maxLevel)
                let height = max(halfHeight * fraction, 4)
                negativeFillGradient
                    .frame(width: innerWidth, height: height)
                    .offset(y: height / 2)
                    .animation(.easeInOut(duration: 0.2), value: level)
                    .overlay(
                        dragActive && height > 12
                        ? waveOverlay(width: innerWidth, height: height, alignTop: false, intensity: fraction)
                        : nil
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: trackCornerRadius - 3, style: .continuous))
    }
    
    private var positiveFillGradient: LinearGradient {
        LinearGradient(
            colors: [
                MoodPalette.positivePrimary.opacity(0.9),
                ColorTheme.stemGreen.opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var negativeFillGradient: LinearGradient {
        LinearGradient(
            colors: [
                MoodPalette.negativePrimary.opacity(0.95),
                ColorTheme.moodDownRed.opacity(0.9)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    @ViewBuilder
    private func tickMarks(in size: CGSize) -> some View {
        ForEach(minLevel...maxLevel, id: \.self) { value in
            let isAnchor = value == 0 || value == minLevel || value == maxLevel
            Rectangle()
                .fill(Color.white.opacity(isAnchor ? 0.6 : 0.25))
                .frame(width: isAnchor ? size.width - 24 : 18, height: isAnchor ? 2 : 1)
                .position(x: size.width / 2, y: position(for: value, in: size.height))
        }
    }
    
    private func handle(in size: CGSize) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 46, height: 46)
            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 6)
            .overlay(
                Circle()
                    .stroke(handleColor, lineWidth: 4)
            )
            .overlay(
                Text(handleEmoji)
                    .font(.system(size: 22))
            )
            .position(x: size.width / 2, y: position(for: level, in: size.height))
            .zIndex(2)
            .highPriorityGesture(
                TapGesture(count: 2).onEnded {
                    guard !disabled else { return }
                    onDoubleTap()
                }
            )
    }
    
    private var handleColor: Color {
        switch level {
        case 1...5:
            return MoodPalette.positivePrimary
        case -5...(-1):
            return MoodPalette.negativePrimary
        default:
            return ColorTheme.pebbleGray
        }
    }
    
    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !disabled else { return }
                if !dragActive {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dragActive = true
                    }
                }
                withAnimation(.linear(duration: 0.12)) {
                    wavePhase += 0.5
                }
                _ = updateLevel(for: value.location.y, height: size.height)
            }
            .onEnded { value in
                guard !disabled else { return }
                let finalLevel = updateLevel(for: value.location.y, height: size.height)
                withAnimation(.easeOut(duration: 0.3)) {
                    dragActive = false
                }
                onCommit(finalLevel)
            }
    }
    
    @discardableResult
    private func updateLevel(for locationY: CGFloat, height: CGFloat) -> Int {
        let clampedY = min(max(locationY, 0), height)
        let ratio = 1 - (clampedY / height) // 0 bottom, 1 top
        let raw = ratio * CGFloat(maxLevel - minLevel) + CGFloat(minLevel)
        let snapped = max(min(maxLevel, Int(raw.rounded())), minLevel)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            level = snapped
        }
        return snapped
    }
    
    private func position(for value: Int, in height: CGFloat) -> CGFloat {
        let handleRadius: CGFloat = 23 // half of 46pt handle
        let usableHeight = max(0, height - handleRadius * 2)
        let ratio = CGFloat(value - minLevel) / CGFloat(maxLevel - minLevel)
        return handleRadius + (1 - ratio) * usableHeight
    }
    
    private func waveOverlay(width: CGFloat, height: CGFloat, alignTop: Bool, intensity: CGFloat) -> some View {
        let base = min(36, height / 1.1)
        let waveHeight = max(6, base * min(1.15, max(0.15, intensity * 1.1)))
        return WaveShape(
            phase: wavePhase,
            amplitude: dragActive ? waveHeight : 0,
            isSpiky: !alignTop
        )
        .stroke(Color.white.opacity(0.35), lineWidth: 3)
        .frame(width: width, height: height)
        .rotationEffect(alignTop ? .zero : .degrees(180))
        .blendMode(.screen)
        .animation(.linear(duration: 0.12), value: wavePhase)
    }
    
    private var handleEmoji: String {
        switch level {
        case 1...5:
            return "😊"
        case -5...(-1):
            return "🙁"
        default:
            return "🧘"
        }
    }
}

#Preview {
    MoodLoggingView()
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var isSpiky: Bool = false
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(phase, amplitude) }
        set {
            phase = newValue.first
            amplitude = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midY = rect.midY
        let waveHeight = max(0, min(amplitude, rect.height / 2))
        let steps = max(12, Int(width / 6))
        path.move(to: CGPoint(x: 0, y: midY))
        for step in 0...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            let x = progress * width
            let angle = progress * .pi * 2 + phase
            let waveValue: CGFloat
            if isSpiky {
                waveValue = (2 / .pi) * asin(sin(angle))
            } else {
                waveValue = sin(angle)
            }
            let y = midY + waveValue * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}


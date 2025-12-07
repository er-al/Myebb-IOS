import SwiftUI

struct DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stats: DashboardStats?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var selectedRange: DashboardRange = .monthly
    @State private var showContent = false
    @State private var gaugeProgress: Double = 0
    @State private var heroPulse = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [ColorTheme.lilyWhite, Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Picker("", selection: $selectedRange) {
                        ForEach(DashboardRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedRange) { _ in
                        Task { await loadStats() }
                    }
                    
                    if isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Syncing your vibe...")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        Spacer()
                    } else if let stats {
                        if stats.totalEntries == 0 {
                            emptyStateView()
                        } else {
                            ScrollView {
                                content(for: stats)
                                    .padding(.horizontal)
                                    .padding(.bottom, 28)
                            }
                        }
                    } else {
                        emptyStateView()
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ColorTheme.stemGreen)
                }
            }
            .onAppear {
                Task { await loadStats() }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    heroPulse = true
                }
            }
            .alert("Dashboard Error", isPresented: .constant(!errorMessage.isEmpty)) {
                Button("OK") { errorMessage = "" }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: stats) { newValue in
                guard let stats = newValue else { return }
                withAnimation(.easeOut(duration: 0.9)) {
                    gaugeProgress = balanceScore(for: stats)
                    showContent = true
                }
            }
        }
        .tint(ColorTheme.stemGreen)
    }
    
    private func content(for stats: DashboardStats) -> some View {
        LazyVStack(spacing: 24) {
            heroSection(stats)
            coreMetrics(stats)
            energyMix(stats)
            resilienceSection(stats)
            trendSection(stats)
            focusSection(stats)
        }
        .opacity(showContent ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: showContent)
    }
    
    private func heroSection(_ stats: DashboardStats) -> some View {
        let balance = balanceScore(for: stats)
        let upIntensity = stats.avgUpIntensity
        let downIntensity = stats.avgDownIntensity
        
        return ZStack {
            LinearGradient(colors: [ColorTheme.stemGreen, ColorTheme.moodUpGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(32)
                .shadow(color: ColorTheme.stemGreen.opacity(0.35), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .scaleEffect(heroPulse ? 1.01 : 0.99)
            
            VStack(alignment: .leading, spacing: 18) {
                Text("Emotional Climate")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(alignment: .center, spacing: 24) {
                    GaugeRing(progress: gaugeProgress)
                        .frame(width: 140, height: 140)
                        .accessibilityLabel("Balance meter")
                        .overlay(
                            VStack(spacing: 4) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(Int(balance * 100))%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                Text(vibeLabel(for: stats))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your vibe is trending \(balance >= 0.55 ? "positive" : "grounded") today.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 16) {
                            metricChip(title: "Avg Up", value: String(format: "%.1f", upIntensity), icon: "arrow.up", color: Color.white.opacity(0.2))
                            metricChip(title: "Avg Down", value: String(format: "%.1f", downIntensity), icon: "arrow.down", color: Color.white.opacity(0.15))
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(24)
        }
    }
    
    private func metricChip(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: true, vertical: false)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color)
        .cornerRadius(12)
        .frame(minWidth: 80)
    }
    
    private func coreMetrics(_ stats: DashboardStats) -> some View {
        let items: [MetricCard] = [
            MetricCard(title: "Win Rate", value: stats.winRateFormatted, detail: stats.momentumText, icon: "sparkle", gradient: [ColorTheme.stemGreen, ColorTheme.moodUpGreen]),
            MetricCard(title: "Entries", value: "\(stats.totalEntries)", detail: selectedRange == .weekly ? "This week" : "This period", icon: "calendar", gradient: [ColorTheme.lakeBlue, ColorTheme.lilyLavender]),
            MetricCard(title: "Momentum", value: momentumScoreDisplay(for: stats), detail: "Your emotional flow", icon: "bolt.fill", gradient: [ColorTheme.petalRose, ColorTheme.peachOrange])
        ]
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                    Text(item.title.uppercased())
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(item.value)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .background(
                    LinearGradient(colors: item.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(22)
                .shadow(color: item.gradient.last?.opacity(0.35) ?? .black.opacity(0.25), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private func energyMix(_ stats: DashboardStats) -> some View {
        let split = energySplit(for: stats)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Energy Mix")
                    .font(.headline)
                    .foregroundColor(ColorTheme.textPrimary)
                Spacer()
                Text(selectedRange.label)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            
            GeometryReader { geo in
                let width = geo.size.width
                let upWidth = max(0, width * split.up)
                let downWidth = max(0, width * split.down)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ColorTheme.mistGray.opacity(0.6))
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(LinearGradient(colors: [ColorTheme.moodUpGreen, ColorTheme.stemGreen], startPoint: .leading, endPoint: .trailing))
                            .frame(width: upWidth)
                            .animation(.easeInOut(duration: 0.8), value: split.up)
                        Capsule()
                            .fill(LinearGradient(colors: [ColorTheme.moodDownRed, ColorTheme.petalRose], startPoint: .leading, endPoint: .trailing))
                            .frame(width: downWidth)
                            .animation(.easeInOut(duration: 0.8), value: split.down)
                    }
                }
                .frame(height: 18)
            }
            .frame(height: 18)
            
            HStack {
                Label("Up Days \(Int(split.up * 100))%", systemImage: "arrow.up")
                    .foregroundColor(ColorTheme.moodUpGreen)
                Spacer()
                Label("Down Days \(Int(split.down * 100))%", systemImage: "arrow.down")
                    .foregroundColor(ColorTheme.moodDownRed)
            }
            .font(.caption)
        }
        .padding()
        .background(ColorTheme.mistGray.opacity(0.45))
        .cornerRadius(22)
    }
    
    private func resilienceSection(_ stats: DashboardStats) -> some View {
        let streakRatio = min(1, Double(stats.currentStreak) / max(1, Double(stats.longestStreak)))
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Resilience")
                .font(.headline)
                .foregroundColor(ColorTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                streakRow(title: "Current Streak", value: "\(stats.currentStreak) days", ratio: streakRatio, tint: ColorTheme.stemGreen)
                streakRow(title: "Best Run", value: "\(stats.longestStreak) days", ratio: 1, tint: ColorTheme.pebbleGray.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
    
    private func streakRow(title: String, value: String, ratio: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textPrimary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            GeometryReader { geo in
                Capsule()
                    .fill(ColorTheme.mistGray.opacity(0.6))
                    .overlay(
                        Capsule()
                            .fill(tint)
                            .frame(width: geo.size.width * ratio)
                            .animation(.spring(response: 0.7, dampingFraction: 0.8), value: ratio)
                    )
            }
            .frame(height: 10)
        }
    }
    
    private func trendSection(_ stats: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Flow")
                    .font(.headline)
                    .foregroundColor(ColorTheme.textPrimary)
                Spacer()
                Text("Last \(stats.recentPerformance.count) days")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            
            MoodTrendChart(points: stats.recentPerformance)
                .frame(height: 180)
                .background(ColorTheme.mistGray.opacity(0.3))
                .cornerRadius(22)
            
            HStack {
                trendBadge(title: "High", value: stats.avgUpIntensity, tint: ColorTheme.moodUpGreen)
                trendBadge(title: "Low", value: stats.avgDownIntensity, tint: ColorTheme.moodDownRed)
                trendBadge(title: "Wins", value: Double(stats.wins), tint: ColorTheme.lakeBlue)
            }
        }
    }
    
    private func trendBadge(title: String, value: Double, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(ColorTheme.textSecondary)
            Text(String(format: "%.1f", value))
                .font(.headline)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(tint.opacity(0.15))
        .cornerRadius(16)
    }
    
    private func focusSection(_ stats: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus ideas")
                .font(.headline)
                .foregroundColor(ColorTheme.textPrimary)
            
            ForEach(focusIdeas(for: stats)) { idea in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: idea.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(idea.color)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(idea.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTheme.textPrimary)
                        Text(idea.subtitle)
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func emptyStateView() -> some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ColorTheme.textSecondary)
                Text("No insights yet")
                    .font(.headline)
                    .foregroundColor(ColorTheme.textPrimary)
                Text("Log a few states to unlock your dashboard insights.")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }
    
    private func focusIdeas(for stats: DashboardStats) -> [FocusIdea] {
        let upPercent = Int(energySplit(for: stats).up * 100)
        let downEnergy = Int((stats.avgDownIntensity / 5) * 100)
        let streak = stats.currentStreak
        
        return [
            FocusIdea(title: "Celebrate wins", subtitle: "\(upPercent)% of your days are trending up. Capture what works and repeat it tomorrow.", icon: "sun.max.fill", color: ColorTheme.moodUpGreen),
            FocusIdea(title: "Gentle reset", subtitle: "Down days average \(downEnergy)% intensity. Try a short walk or journal to reset.", icon: "leaf.fill", color: ColorTheme.lakeBlue),
            FocusIdea(title: "Rhythm check", subtitle: "Streak of \(streak) days. Plan a reward to keep the streak going.", icon: "sparkles", color: ColorTheme.petalRose)
        ]
    }
    
    private func balanceScore(for stats: DashboardStats) -> Double {
        let total = max(1, stats.wins + stats.losses)
        return Double(stats.wins) / Double(total)
    }
    
    private func energySplit(for stats: DashboardStats) -> (up: Double, down: Double) {
        let total = max(1, stats.wins + stats.losses)
        let up = Double(stats.wins) / Double(total)
        let down = Double(stats.losses) / Double(total)
        return (up, down)
    }
    
    private func vibeLabel(for stats: DashboardStats) -> String {
        let score = balanceScore(for: stats)
        if score >= 0.75 { return "radiant" }
        if score >= 0.55 { return "steady" }
        return "reflective"
    }

    /// Calculates momentum as a percentage based on positive days and consistency
    /// Formula: (Positive Days / Total Days) × 100 + Streak Bonus (max 10%)
    /// Example: 7 wins out of 10 days = 70% + 3-day streak bonus = 73%
    private func momentumScoreDisplay(for stats: DashboardStats) -> String {
        let total = stats.wins + stats.losses
        if total == 0 { return "50%" } // Default when no data

        let baseScore = Double(stats.wins) / Double(total) // Win rate percentage
        let streakBonus = min(0.1, Double(stats.currentStreak) * 0.01) // 1% per streak day, max 10%
        let finalScore = min(1.0, baseScore + streakBonus) // Cap at 100%

        return String(format: "%.0f%%", finalScore * 100)
    }

    private func momentumDescription(for stats: DashboardStats) -> String {
        let total = stats.wins + stats.losses
        if total == 0 { return "Track more days to see momentum" }

        let winRate = Double(stats.wins) / Double(total)
        if winRate >= 0.7 {
            return "Strong positive momentum"
        } else if winRate >= 0.5 {
            return "Balanced momentum"
        } else {
            return "Building momentum"
        }
    }
    
    private func loadStats() async {
        isLoading = true
        errorMessage = ""
        showContent = false
        
        do {
            let result = try await APIService.shared.getDashboardStats(range: selectedRange)
            await MainActor.run {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                    self.stats = result
                    self.gaugeProgress = balanceScore(for: result)
                    self.showContent = true
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if let apiError = error as? APIError {
                    switch apiError {
                    case .serverError(let message):
                        self.errorMessage = message
                    case .unauthorized:
                        self.errorMessage = "Session expired. Please log in again."
                    default:
                        self.errorMessage = "Failed to load dashboard."
                    }
                } else {
                    self.errorMessage = "Failed to load dashboard."
                }
            }
        }
    }
}

private struct GaugeRing: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 18)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Color.white, Color.white.opacity(0.7)], center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}

private struct MetricCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let icon: String
    let gradient: [Color]
}

private struct FocusIdea: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

private struct MoodTrendChart: View {
    let points: [DailyPerformancePoint]
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let resolved = resolvedPoints(in: geo.size)
            let linePath = path(for: resolved)
            let fillPath = fill(for: resolved, in: geo.size)
            
            ZStack {
                fillPath
                    .fill(LinearGradient(colors: [ColorTheme.stemGreen.opacity(0.25), Color.clear], startPoint: .top, endPoint: .bottom))
                    .opacity(0.4)
                linePath
                    .trim(from: 0, to: progress)
                    .stroke(LinearGradient(colors: [ColorTheme.stemGreen, ColorTheme.moodUpGreen], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                    .animation(.easeOut(duration: 1.2), value: progress)
                linePath
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                
                ForEach(Array(resolved.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .position(point)
                        .opacity(progress > CGFloat(index) / CGFloat(max(resolved.count - 1, 1)) ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.03), value: progress)
                }
            }
            .background(
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Divider().background(ColorTheme.mistGray)
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            )
        }
        .padding(.vertical, 8)
        .onAppear {
            progress = 0
            withAnimation(.easeOut(duration: 1.2)) {
                progress = 1
            }
        }
    }
    
    private func resolvedPoints(in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let values = points.map { value(for: $0) }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 0.1)
        let stepX = size.width / CGFloat(max(points.count - 1, 1))
        
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let normalizedY = 1 - CGFloat((value - minValue) / range)
            let y = normalizedY * size.height
            return CGPoint(x: x, y: y)
        }
    }
    
    private func value(for point: DailyPerformancePoint) -> Double {
        let intensity = Double(point.intensity ?? 3)
        switch point.outcome {
        case 1:
            return 5 + intensity
        case 0:
            return -5 + (intensity * 0.4)
        default:
            return 0
        }
    }
    
    private func path(for points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
    
    private func fill(for points: [CGPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.closeSubpath()
        return path
    }
}

#if DEBUG
#Preview {
    DashboardView()
}
#endif

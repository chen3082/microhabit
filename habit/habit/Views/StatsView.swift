import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // 分段控制器
                Picker("", selection: $selectedTab) {
                    Text("數據").tag(0)
                    Text("成就").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                if selectedTab == 0 {
                    StatisticsTabView()
                        .environmentObject(habitStore)
                } else {
                    AchievementsTabView()
                        .environmentObject(habitStore)
                }
            }
            .navigationTitle("統計")
        }
    }
}

struct StatisticsTabView: View {
    @EnvironmentObject private var habitStore: HabitStore
    
    private var statistics: HabitStatistics {
        habitStore.getStatistics()
    }
    
    var body: some View {
        if habitStore.habits.isEmpty {
            EmptyStateView(
                title: "還沒有數據",
                message: "開始養成習慣後，這裡會顯示統計數據",
                icon: "chart.bar.xaxis"
            )
            .padding()
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    // 概覽卡片
                    StatsCardView(
                        title: "習慣概覽",
                        icon: "chart.pie.fill",
                        color: .purple
                    ) {
                        // 卡片內容
                        VStack(spacing: 16) {
                            StatsRowView(
                                title: "習慣總數",
                                value: "\(statistics.totalHabits)",
                                icon: "list.bullet",
                                color: .blue
                            )
                            
                            Divider()
                            
                            StatsRowView(
                                title: "完成次數",
                                value: "\(statistics.totalCompletions)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            Divider()
                            
                            StatsRowView(
                                title: "完成率",
                                value: "\(Int(statistics.completionRate * 100))%",
                                icon: "percent",
                                color: .orange
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 連續記錄卡片
                    StatsCardView(
                        title: "連續記錄",
                        icon: "flame.fill",
                        color: .orange
                    ) {
                        // 卡片內容
                        VStack(spacing: 16) {
                            if statistics.bestStreak > 0 {
                                StatsRowView(
                                    title: "最長連續天數",
                                    value: "\(statistics.bestStreak) 天",
                                    icon: "star.fill",
                                    color: .yellow
                                )
                                
                                Divider()
                                
                                StatsRowView(
                                    title: "最佳習慣",
                                    value: statistics.bestStreakHabit,
                                    icon: "heart.fill",
                                    color: .red
                                )
                            } else {
                                Text("還沒有連續記錄")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 習慣排行卡片
                    StatsCardView(
                        title: "習慣排行",
                        icon: "list.number",
                        color: .blue
                    ) {
                        // 卡片內容
                        VStack(spacing: 16) {
                            if !habitStore.habits.isEmpty {
                                ForEach(getTopHabits()) { habit in
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: habit.icon)
                                                .font(.system(size: 16))
                                        }
                                        
                                        Text(habit.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(habit.completions.count) 次")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if habit.id != getTopHabits().last?.id {
                                        Divider()
                                    }
                                }
                            } else {
                                Text("還沒有習慣記錄")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
    }
    
    // 獲取完成次數最多的前三個習慣
    private func getTopHabits() -> [Habit] {
        return Array(habitStore.habits.sorted(by: { $0.completions.count > $1.completions.count }).prefix(3))
    }
}

struct AchievementsTabView: View {
    @EnvironmentObject private var habitStore: HabitStore
    
    var unlockedAchievements: [Achievement] {
        habitStore.achievements.filter { $0.unlocked }
    }
    
    var lockedAchievements: [Achievement] {
        habitStore.achievements.filter { !$0.unlocked }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 已解鎖成就
                if !unlockedAchievements.isEmpty {
                    Text("已解鎖成就")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(unlockedAchievements) { achievement in
                        AchievementCardView(achievement: achievement, unlocked: true)
                            .padding(.horizontal)
                    }
                }
                
                // 未解鎖成就
                if !lockedAchievements.isEmpty {
                    Text("未解鎖成就")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, unlockedAchievements.isEmpty ? 0 : 16)
                    
                    ForEach(lockedAchievements) { achievement in
                        AchievementCardView(achievement: achievement, unlocked: false)
                            .padding(.horizontal)
                    }
                }
                
                if habitStore.achievements.isEmpty {
                    EmptyStateView(
                        title: "還沒有成就",
                        message: "開始養成習慣後，你將解鎖各種成就",
                        icon: "star.fill"
                    )
                    .padding()
                }
            }
            .padding(.vertical)
        }
    }
}

struct StatsCardView<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
            }
            
            // 內容
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatsRowView: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack {
            // 圖標和標題
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // 數值
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

struct AchievementCardView: View {
    var achievement: Achievement
    var unlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 圖標
            ZStack {
                Circle()
                    .fill(unlocked ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                    .frame(width: 50, height: 50)
                
                if unlocked {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            // 文字內容
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if unlocked, let date = achievement.unlockedDate {
                    Text("解鎖於：\(formatDate(date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(unlocked ? 1.0 : 0.7)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(HabitStore())
    }
} 
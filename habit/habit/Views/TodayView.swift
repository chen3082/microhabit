import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct TodayView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var showingTip = true
    @State private var showingNewHabitSheet = false
    @State private var showingAchievementAlert = false
    @State private var newAchievement: Achievement? = nil
    
    var todayHabits: [Habit] {
        habitStore.habits.filter { habit in
            habit.shouldComplete(on: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if todayHabits.isEmpty {
                    EmptyStateView(
                        title: "今天沒有需要完成的習慣",
                        message: "點擊下方按鈕新增一個習慣吧",
                        icon: "sparkles"
                    )
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 顯示激勵提示
                            if showingTip {
                                TipView(isShowing: $showingTip)
                                    .padding(.horizontal)
                                    .padding(.top)
                            }
                            
                            // 顯示今日習慣
                            VStack(spacing: 12) {
                                ForEach(todayHabits) { habit in
                                    HabitCardView(habit: habit, onToggle: {
                                        withAnimation {
                                            habitStore.toggleHabitCompletion(habit)
                                            
                                            // 檢查成就
                                            habitStore.checkAchievements()
                                            
                                            // 檢查是否有新成就
                                            checkForNewAchievements()
                                        }
                                    })
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, showingTip ? 8 : 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("今日習慣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewHabitSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingNewHabitSheet) {
                NewHabitView(isPresented: $showingNewHabitSheet)
                    .environmentObject(habitStore)
            }
            .alert(isPresented: $showingAchievementAlert, content: {
                Alert(
                    title: Text("恭喜！🎉"),
                    message: Text("你解鎖了成就「\(newAchievement?.title ?? "")」"),
                    dismissButton: .default(Text("太棒了！"))
                )
            })
        }
    }
    
    private func checkForNewAchievements() {
        if let achievement = habitStore.achievements.first(where: { 
            $0.unlocked && $0.unlockedDate != nil && 
            Calendar.current.isDateInToday($0.unlockedDate!)
        }) {
            newAchievement = achievement
            showingAchievementAlert = true
        }
    }
}

struct TipView: View {
    @Binding var isShowing: Bool
    
    let tips = [
        "習慣需要時間養成，每天進步一點點",
        "把習慣與你已有的行為綁定在一起",
        "設定明確的時間和地點有助於習慣形成",
        "讓好習慣變得明顯、有吸引力、簡單且令人滿足",
        "每完成一次，給自己一個小獎勵"
    ]
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title3)
                .padding(.leading, 2)
            
            Text("\(tips.randomElement() ?? tips[0])")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.vertical, 10)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowing = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemGray6)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HabitCardView: View {
    var habit: Habit
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            // 習慣圖標
            ZStack {
                Circle()
                    .fill(habit.isCompletedToday() ? Color.green.opacity(0.2) : Color.systemGray6)
                    .frame(width: 50, height: 50)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 22))
                    .foregroundColor(habit.isCompletedToday() ? .green : .primary)
            }
            .padding(.trailing, 6)
            
            // 習慣信息
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("\(habit.frequency.rawValue)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if habit.timeGoal != nil {
                        Label(getFormattedTime(from: habit.timeGoal!), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 完成按鈕
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedToday() ? Color.green : Color.systemGray4, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if habit.isCompletedToday() {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondarySystemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(habit.isCompletedToday() ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func getFormattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .environmentObject(HabitStore())
    }
} 
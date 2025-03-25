import Foundation
import Combine

class HabitStore: ObservableObject {
    // 發布所有習慣變化的訂閱
    @Published var habits: [Habit] = []
    
    // 成就資料
    @Published var achievements: [Achievement] = []
    
    // 用於存儲的鍵
    private let habitsKey = "habits"
    private let achievementsKey = "achievements"
    
    // 初始化時加載數據
    init() {
        loadHabits()
        loadAchievements()
        
        // 如果沒有成就，初始化默認成就
        if achievements.isEmpty {
            initializeDefaultAchievements()
        }
        
        // 檢查是否有新的成就解鎖
        checkAchievements()
    }
    
    // 加載習慣數據
    private func loadHabits() {
        guard let data = UserDefaults.standard.data(forKey: habitsKey) else {
            habits = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            habits = try decoder.decode([Habit].self, from: data)
        } catch {
            print("無法解碼習慣數據: \(error)")
            habits = []
        }
    }
    
    // 保存習慣數據
    private func saveHabits() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(habits)
            UserDefaults.standard.set(data, forKey: habitsKey)
        } catch {
            print("無法保存習慣數據: \(error)")
        }
    }
    
    // 加載成就數據
    private func loadAchievements() {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey) else {
            achievements = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            achievements = try decoder.decode([Achievement].self, from: data)
        } catch {
            print("無法解碼成就數據: \(error)")
            achievements = []
        }
    }
    
    // 保存成就數據
    private func saveAchievements() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(achievements)
            UserDefaults.standard.set(data, forKey: achievementsKey)
        } catch {
            print("無法保存成就數據: \(error)")
        }
    }
    
    // 添加習慣
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        checkAchievements()
    }
    
    // 更新習慣
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
            checkAchievements()
        }
    }
    
    // 刪除習慣
    func deleteHabit(at indexSet: IndexSet) {
        habits.remove(atOffsets: indexSet)
        saveHabits()
    }
    
    // 刪除指定ID的習慣
    func deleteHabit(id: UUID) {
        habits.removeAll(where: { $0.id == id })
        saveHabits()
    }
    
    // 切換習慣的完成狀態
    func toggleHabitCompletion(_ habit: Habit) {
        if var habit = habits.first(where: { $0.id == habit.id }) {
            habit.toggleCompletion()
            updateHabit(habit)
        }
    }
    
    // 初始化默認成就
    private func initializeDefaultAchievements() {
        achievements = [
            Achievement(
                id: UUID(),
                title: "第一次嘗試",
                description: "創建你的第一個習慣",
                type: .habits,
                requirement: 1,
                icon: "star.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "習慣養成者",
                description: "創建5個習慣",
                type: .habits,
                requirement: 5,
                icon: "star.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "習慣大師",
                description: "創建10個習慣",
                type: .habits,
                requirement: 10,
                icon: "star.circle.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "第一步",
                description: "完成第一次習慣",
                type: .completions,
                requirement: 1,
                icon: "checkmark.circle.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "持之以恆",
                description: "連續完成同一習慣7天",
                type: .streak,
                requirement: 7,
                icon: "flame.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "堅持不懈",
                description: "連續完成同一習慣30天",
                type: .streak,
                requirement: 30,
                icon: "flame.circle.fill",
                unlocked: false
            ),
            Achievement(
                id: UUID(),
                title: "三分鐘熱度",
                description: "放棄一個習慣後重新開始",
                type: .restart,
                requirement: 1,
                icon: "arrow.counterclockwise.circle.fill",
                unlocked: false
            )
        ]
        saveAchievements()
    }
    
    // 檢查成就是否解鎖
    func checkAchievements() {
        var updated = false
        
        // 檢查每個成就
        for i in 0..<achievements.count {
            if !achievements[i].unlocked {
                switch achievements[i].type {
                case .habits:
                    if habits.count >= achievements[i].requirement {
                        achievements[i].unlocked = true
                        achievements[i].unlockedDate = Date()
                        updated = true
                    }
                    
                case .completions:
                    let totalCompletions = habits.reduce(0) { $0 + $1.completions.count }
                    if totalCompletions >= achievements[i].requirement {
                        achievements[i].unlocked = true
                        achievements[i].unlockedDate = Date()
                        updated = true
                    }
                    
                case .streak:
                    if habits.contains(where: { $0.currentStreak >= achievements[i].requirement }) {
                        achievements[i].unlocked = true
                        achievements[i].unlockedDate = Date()
                        updated = true
                    }
                    
                case .restart:
                    // 這個暫時無法自動檢測，需要手動觸發
                    break
                }
            }
        }
        
        if updated {
            saveAchievements()
        }
    }
    
    // 手動觸發特定成就（如果需要）
    func triggerAchievement(type: Achievement.AchievementType) {
        if let index = achievements.firstIndex(where: { $0.type == type && !$0.unlocked }) {
            achievements[index].unlocked = true
            achievements[index].unlockedDate = Date()
            saveAchievements()
        }
    }
    
    // 获取统计数据
    func getStatistics() -> HabitStatistics {
        let totalHabits = habits.count
        let totalCompletions = habits.reduce(0) { $0 + $1.completions.count }
        let avgCompletionRate = habits.isEmpty ? 0 : habits.reduce(0.0) { $0 + $1.completionRate } / Double(habits.count)
        let bestStreakHabit = habits.max(by: { $0.bestStreak < $1.bestStreak })
        let bestStreak = bestStreakHabit?.bestStreak ?? 0
        
        return HabitStatistics(
            totalHabits: totalHabits,
            totalCompletions: totalCompletions,
            completionRate: avgCompletionRate,
            bestStreak: bestStreak,
            bestStreakHabit: bestStreakHabit?.name ?? ""
        )
    }
} 
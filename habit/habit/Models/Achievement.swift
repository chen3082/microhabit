import Foundation

struct Achievement: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var type: AchievementType
    var requirement: Int
    var icon: String
    var unlocked: Bool
    var unlockedDate: Date?
    
    enum AchievementType: String, Codable {
        case habits      // 基於創建的習慣數量
        case completions // 基於完成的習慣次數
        case streak      // 基於連續完成天數
        case restart     // 基於重新開始習慣
    }
}

struct HabitStatistics {
    var totalHabits: Int
    var totalCompletions: Int
    var completionRate: Double
    var bestStreak: Int
    var bestStreakHabit: String
} 
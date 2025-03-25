import Foundation

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var icon: String
    var frequency: Frequency
    var timeGoal: Date?
    var cue: String
    var motivation: String
    var steps: String
    var reward: String
    var createdAt: Date
    var completions: [Date]
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var bestStreak: Int {
        calculateBestStreak()
    }
    
    var completionRate: Double {
        calculateCompletionRate()
    }
    
    enum Frequency: String, Codable, CaseIterable {
        case daily = "每天"
        case weekly = "每週"
        case weekdays = "工作日"
        case weekends = "週末"
        case custom = "自定義"
    }
    
    init(name: String, icon: String, frequency: Frequency, timeGoal: Date? = nil, cue: String = "", motivation: String = "", steps: String = "", reward: String = "") {
        self.name = name
        self.icon = icon
        self.frequency = frequency
        self.timeGoal = timeGoal
        self.cue = cue
        self.motivation = motivation
        self.steps = steps
        self.reward = reward
        self.createdAt = Date()
        self.completions = []
    }
    
    // 檢查今天是否已完成
    func isCompletedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) })
    }
    
    // 獲取指定日期的完成狀態
    func isCompleted(on date: Date) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return completions.contains(where: { Calendar.current.isDate($0, inSameDayAs: targetDate) })
    }
    
    // 檢查是否應該在指定日期完成（基於頻率）
    func shouldComplete(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        switch frequency {
        case .daily:
            return true
        case .weekly:
            // 假設每週一為固定日
            return weekday == 2
        case .weekdays:
            return (2...6).contains(weekday) // 週一到週五
        case .weekends:
            return weekday == 1 || weekday == 7 // 週日或週六
        case .custom:
            // 自定義頻率（可擴展）
            return true
        }
    }
    
    // 計算當前連續天數
    private func calculateCurrentStreak() -> Int {
        guard !completions.isEmpty else { return 0 }
        
        let sortedCompletions = completions.sorted(by: >)
        var streak = 0
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // 檢查今天或昨天是否有完成
        let hasRecentCompletion = completions.contains(where: { 
            Calendar.current.isDate($0, inSameDayAs: today) || 
            Calendar.current.isDate($0, inSameDayAs: yesterday)
        })
        
        // 如果最近沒有完成，返回0
        if !hasRecentCompletion {
            return 0
        }
        
        // 回溯計算連續天數
        var currentDate = today
        
        while true {
            // 檢查當前日期是否應該完成
            if shouldComplete(on: currentDate) {
                // 如果應該完成但沒有完成，中斷連續
                if !isCompleted(on: currentDate) && !Calendar.current.isDateInTomorrow(currentDate) {
                    break
                }
                // 如果完成了，增加計數
                if isCompleted(on: currentDate) {
                    streak += 1
                }
            }
            
            // 前一天
            guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }
        
        return streak
    }
    
    // 計算最佳連續天數
    private func calculateBestStreak() -> Int {
        guard !completions.isEmpty else { return 0 }
        
        let dateCompletions = completions.map { Calendar.current.startOfDay(for: $0) }
        let sortedDates = Array(Set(dateCompletions)).sorted()
        
        var bestStreak = 0
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            // 檢查是否為連續日期
            let dayDifference = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if dayDifference == 1 {
                currentStreak += 1
            } else {
                bestStreak = max(bestStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        bestStreak = max(bestStreak, currentStreak)
        return bestStreak
    }
    
    // 計算過去30天的完成率
    private func calculateCompletionRate() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        
        var totalCompletable = 0
        var totalCompleted = 0
        
        var currentDate = thirtyDaysAgo
        while currentDate <= today {
            if shouldComplete(on: currentDate) {
                totalCompletable += 1
                if isCompleted(on: currentDate) {
                    totalCompleted += 1
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return totalCompletable > 0 ? Double(totalCompleted) / Double(totalCompletable) : 0.0
    }
    
    // 切換完成狀態
    mutating func toggleCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = completions.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            // 如果今天已完成，則取消完成
            completions.remove(at: index)
        } else {
            // 如果今天未完成，則標記為完成
            completions.append(today)
        }
    }
} 
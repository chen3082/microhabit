import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var showingNewHabitSheet = false
    @State private var editMode: EditMode = .inactive
    @State private var searchText = ""
    
    var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return habitStore.habits
        } else {
            return habitStore.habits.filter { habit in
                habit.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if habitStore.habits.isEmpty {
                    EmptyStateView(
                        title: "還沒有習慣",
                        message: "點擊下方按鈕創建你的第一個習慣",
                        icon: "plus.circle"
                    )
                    .padding()
                } else {
                    List {
                        ForEach(filteredHabits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitRowView(habit: habit)
                            }
                        }
                        .onDelete(perform: deleteHabits)
                    }
                    .searchable(text: $searchText, prompt: "搜索習慣")
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("我的習慣")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewHabitSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingNewHabitSheet) {
                NewHabitView(isPresented: $showingNewHabitSheet)
                    .environmentObject(habitStore)
            }
        }
    }
    
    private func deleteHabits(at offsets: IndexSet) {
        habitStore.deleteHabit(at: offsets)
    }
}

struct HabitRowView: View {
    var habit: Habit
    
    var body: some View {
        HStack(spacing: 16) {
            // 習慣圖標
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 18))
            }
            
            // 習慣信息
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                
                HStack {
                    // 頻率
                    Text(habit.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 分隔點
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 4, height: 4)
                    
                    // 當前連續天數
                    Text("\(habit.currentStreak) 天連續")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 完成狀態
            if habit.isCompletedToday() {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HabitDetailView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @State private var habit: Habit
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    @State private var date = Date()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    private let calendar = Calendar.current
    
    init(habit: Habit) {
        _habit = State(initialValue: habit)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 習慣頭部信息
                habitHeader
                
                // 完成日曆
                calendarView
                
                // 詳細信息卡片
                detailCards
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isEditing = true
                    }) {
                        Label("編輯", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("刪除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("刪除習慣"),
                message: Text("確定要刪除這個習慣嗎？此操作無法撤銷。"),
                primaryButton: .destructive(Text("刪除")) {
                    habitStore.deleteHabit(id: habit.id)
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isEditing) {
            EditHabitView(habit: $habit, isPresented: $isEditing)
                .environmentObject(habitStore)
        }
    }
    
    // 習慣頭部信息視圖
    private var habitHeader: some View {
        VStack(spacing: 16) {
            // 圖標和名稱
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(habit.frequency.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 16)
                
                Spacer()
            }
            
            // 統計指標
            HStack {
                StatisticItemView(
                    value: "\(habit.currentStreak)",
                    label: "當前連續",
                    icon: "flame.fill",
                    color: .orange
                )
                
                Divider().frame(height: 40)
                
                StatisticItemView(
                    value: "\(habit.bestStreak)",
                    label: "最長連續",
                    icon: "star.fill",
                    color: .yellow
                )
                
                Divider().frame(height: 40)
                
                StatisticItemView(
                    value: "\(Int(habit.completionRate * 100))%",
                    label: "完成率",
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // 日曆視圖
    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 月份選擇器
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(calendar.monthSymbols[selectedMonth - 1]) \(String(selectedYear))")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 8)
            
            // 星期標題
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            // 日期網格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let isCompleted = habit.isCompleted(on: date)
                        let isToday = calendar.isDateInToday(date)
                        let shouldComplete = habit.shouldComplete(on: date)
                        
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color.green.opacity(0.3) : Color.clear)
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .stroke(isToday ? Color.primary : Color.clear, lineWidth: 1)
                                .frame(width: 36, height: 36)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 14))
                                .foregroundColor(shouldComplete ? .primary : .secondary.opacity(0.5))
                        }
                        .frame(height: 40)
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // 詳細信息卡片
    private var detailCards: some View {
        VStack(spacing: 16) {
            // 如果有提示信息
            if !habit.cue.isEmpty {
                DetailCardView(
                    title: "提示",
                    content: habit.cue,
                    icon: "lightbulb.fill",
                    color: .yellow
                )
            }
            
            // 如果有動機信息
            if !habit.motivation.isEmpty {
                DetailCardView(
                    title: "動機",
                    content: habit.motivation,
                    icon: "heart.fill",
                    color: .red
                )
            }
            
            // 如果有步驟信息
            if !habit.steps.isEmpty {
                DetailCardView(
                    title: "步驟",
                    content: habit.steps,
                    icon: "list.bullet",
                    color: .blue
                )
            }
            
            // 如果有獎勵信息
            if !habit.reward.isEmpty {
                DetailCardView(
                    title: "獎勵",
                    content: habit.reward,
                    icon: "gift.fill",
                    color: .purple
                )
            }
        }
    }
    
    // 獲取當月的所有日期
    private func daysInMonth() -> [Date?] {
        var days = [Date?]()
        
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        guard let startDate = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: startDate)
        else {
            return days
        }
        
        // 獲取月初是星期幾
        let firstDay = calendar.component(.weekday, from: startDate)
        
        // 添加月初前的空白
        for _ in 1..<firstDay {
            days.append(nil)
        }
        
        // 添加當月所有日期
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // 切換月份
    private func changeMonth(by value: Int) {
        var newMonth = selectedMonth + value
        var newYear = selectedYear
        
        if newMonth > 12 {
            newMonth = 1
            newYear += 1
        } else if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        }
        
        selectedMonth = newMonth
        selectedYear = newYear
    }
}

struct StatisticItemView: View {
    var value: String
    var label: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailCardView: View {
    var title: String
    var content: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EditHabitView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var habit: Habit
    @Binding var isPresented: Bool
    
    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedFrequency: Habit.Frequency
    @State private var hasTimeGoal: Bool
    @State private var timeGoal: Date
    @State private var cue: String
    @State private var motivation: String
    @State private var steps: String
    @State private var reward: String
    @State private var showingIconPicker = false
    
    private let icons = [
        "heart.fill", "book.fill", "figure.run", "drop.fill", "bed.double.fill", 
        "pills.fill", "fork.knife", "questionmark.circle.fill",
        "brain.head.profile", "bolt.fill", "cart.fill", "leaf.fill", 
        "moon.stars.fill", "music.note", "hands.sparkles.fill", "pencil"
    ]
    
    init(habit: Binding<Habit>, isPresented: Binding<Bool>) {
        self._habit = habit
        self._isPresented = isPresented
        
        self._habitName = State(initialValue: habit.wrappedValue.name)
        self._selectedIcon = State(initialValue: habit.wrappedValue.icon)
        self._selectedFrequency = State(initialValue: habit.wrappedValue.frequency)
        self._hasTimeGoal = State(initialValue: habit.wrappedValue.timeGoal != nil)
        self._timeGoal = State(initialValue: habit.wrappedValue.timeGoal ?? Date())
        self._cue = State(initialValue: habit.wrappedValue.cue)
        self._motivation = State(initialValue: habit.wrappedValue.motivation)
        self._steps = State(initialValue: habit.wrappedValue.steps)
        self._reward = State(initialValue: habit.wrappedValue.reward)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("習慣名稱", text: $habitName)
                    
                    Button(action: {
                        showingIconPicker = true
                    }) {
                        HStack {
                            Text("圖標")
                            
                            Spacer()
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 20))
                                .frame(width: 30, height: 30)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("頻率與時間")) {
                    Picker("重複頻率", selection: $selectedFrequency) {
                        ForEach(Habit.Frequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
                    Toggle("設定固定時間", isOn: $hasTimeGoal)
                    
                    if hasTimeGoal {
                        DatePicker("時間", selection: $timeGoal, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("提示和獎勵")) {
                    TextField("提示（完成習慣的線索）", text: $cue)
                    TextField("動機（為什麼要養成這個習慣）", text: $motivation)
                    TextField("步驟（如何完成這個習慣）", text: $steps)
                    TextField("獎勵（完成後給自己的獎勵）", text: $reward)
                }
            }
            .navigationTitle("編輯習慣")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateHabit()
                        isPresented = false
                    }
                    .disabled(habitName.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, icons: icons)
            }
        }
    }
    
    private func updateHabit() {
        var updatedHabit = habit
        updatedHabit.name = habitName
        updatedHabit.icon = selectedIcon
        updatedHabit.frequency = selectedFrequency
        updatedHabit.timeGoal = hasTimeGoal ? timeGoal : nil
        updatedHabit.cue = cue
        updatedHabit.motivation = motivation
        updatedHabit.steps = steps
        updatedHabit.reward = reward
        
        habitStore.updateHabit(updatedHabit)
        habit = updatedHabit
    }
}

struct HabitsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitsView()
            .environmentObject(HabitStore())
    }
} 
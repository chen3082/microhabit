import SwiftUI

struct NewHabitView: View {
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var isPresented: Bool
    
    @State private var habitName = ""
    @State private var selectedIcon = "heart.fill"
    @State private var selectedFrequency = Habit.Frequency.daily
    @State private var hasTimeGoal = false
    @State private var timeGoal = Date()
    @State private var cue = ""
    @State private var motivation = ""
    @State private var steps = ""
    @State private var reward = ""
    @State private var currentStep = 1
    @State private var showingIconPicker = false
    
    private let icons = [
        "heart.fill", "book.fill", "figure.run", "drop.fill", "bed.double.fill", 
        "pills.fill", "fork.knife", "questionmark.circle.fill",
        "brain.head.profile", "bolt.fill", "cart.fill", "leaf.fill", 
        "moon.stars.fill", "music.note", "hands.sparkles.fill", "pencil"
    ]
    
    private var isStepComplete: Bool {
        switch currentStep {
        case 1:
            return !habitName.isEmpty && !selectedIcon.isEmpty
        case 2:
            return true // 頻率總是有默認值
        case 3:
            return true // 提示和動機都是可選的
        default:
            return true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 進度指示器
                ProgressIndicator(currentStep: currentStep, totalSteps: 3)
                    .padding(.top)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // 步驟 1：基本信息
                        if currentStep == 1 {
                            basicInfoStep
                        }
                        
                        // 步驟 2：頻率和時間
                        else if currentStep == 2 {
                            frequencyStep
                        }
                        
                        // 步驟 3：提示和獎勵
                        else if currentStep == 3 {
                            cueAndRewardStep
                        }
                    }
                    .padding()
                }
                
                // 底部按鈕
                HStack {
                    if currentStep > 1 {
                        Button("上一步") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    if currentStep < 3 {
                        Button("下一步") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isStepComplete)
                    } else {
                        Button("創建習慣") {
                            saveHabit()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isStepComplete)
                    }
                }
                .padding()
            }
            .navigationTitle("新增習慣")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon, icons: icons)
            }
        }
    }
    
    // 步驟 1：基本信息視圖
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("習慣基本信息")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("創建一個明確、可行動的習慣")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("習慣名稱")
                    .font(.headline)
                
                TextField("例如：每天早上喝一杯水", text: $habitName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
                
                Text("選擇圖標")
                    .font(.headline)
                
                Button(action: {
                    showingIconPicker = true
                }) {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                        
                        Text("更換圖標")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // 步驟 2：頻率和時間視圖
    private var frequencyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("習慣頻率設置")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("設定合理的頻率，讓習慣更容易堅持")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("重複頻率")
                    .font(.headline)
                
                Picker("頻率", selection: $selectedFrequency) {
                    ForEach(Habit.Frequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 20)
                
                Toggle(isOn: $hasTimeGoal) {
                    Text("設定固定時間")
                        .font(.headline)
                }
                
                if hasTimeGoal {
                    DatePicker("時間", selection: $timeGoal, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxHeight: 150)
                }
            }
        }
    }
    
    // 步驟 3：提示和獎勵視圖
    private var cueAndRewardStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("提示與獎勵")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("讓習慣更容易堅持的小技巧")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("提示（完成習慣的線索）")
                        .font(.headline)
                    
                    TextField("例如：放一瓶水在床頭", text: $cue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Group {
                    Text("動機（為什麼要養成這個習慣）")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    TextField("例如：保持身體健康，精力充沛", text: $motivation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Group {
                    Text("步驟（如何完成這個習慣）")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    TextField("例如：起床後立即喝一杯水", text: $steps)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Group {
                    Text("獎勵（完成後給自己的獎勵）")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    TextField("例如：感受精力充沛的好心情", text: $reward)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
    
    private func saveHabit() {
        let newHabit = Habit(
            name: habitName,
            icon: selectedIcon,
            frequency: selectedFrequency,
            timeGoal: hasTimeGoal ? timeGoal : nil,
            cue: cue,
            motivation: motivation,
            steps: steps,
            reward: reward
        )
        
        habitStore.addHabit(newHabit)
        isPresented = false
    }
}

struct ProgressIndicator: View {
    var currentStep: Int
    var totalSteps: Int
    
    var body: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(step <= currentStep ? .orange : Color(.systemGray4))
                
                if step < totalSteps {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(step < currentStep ? .orange : Color(.systemGray4))
                }
            }
        }
        .padding(.horizontal)
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String
    var icons: [String]
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.orange.opacity(0.2) : Color(.systemGray6))
                                    .foregroundColor(selectedIcon == icon ? .orange : .primary)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("選擇圖標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 100)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 100)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct NewHabitView_Previews: PreviewProvider {
    static var previews: some View {
        NewHabitView(isPresented: .constant(true))
            .environmentObject(HabitStore())
    }
} 
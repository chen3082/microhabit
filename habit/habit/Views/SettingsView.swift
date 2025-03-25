import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date()
    @State private var showingInfoSheet = false
    @State private var selectedInfo: InfoContent?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外觀")) {
                    Toggle("深色模式", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { newValue in
                            setAppearance(darkMode: newValue)
                        }
                }
                
                Section(header: Text("通知")) {
                    Toggle("啟用通知", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("每日提醒時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _ in
                                // 更新提醒時間邏輯
                            }
                    }
                }
                
                Section(header: Text("知識庫")) {
                    ForEach(infoContents) { info in
                        Button(action: {
                            selectedInfo = info
                            showingInfoSheet = true
                        }) {
                            HStack {
                                Image(systemName: info.icon)
                                    .foregroundColor(info.color)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                Text(info.title)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    #if canImport(UIKit) && !targetEnvironment(macCatalyst)
                    Button(action: {
                        // 分享應用
                        let activityVC = UIActivityViewController(
                            activityItems: ["體驗原子習慣追蹤器：幫助你養成良好習慣！"],
                            applicationActivities: nil
                        )
                        
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = scene.windows.first?.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    }) {
                        HStack {
                            Text("分享應用")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    #else
                    Button(action: {
                        // macOS 分享功能
                        // 可以在這裡添加 macOS 的分享實現
                    }) {
                        HStack {
                            Text("分享應用")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("設置")
            .sheet(isPresented: $showingInfoSheet) {
                if let info = selectedInfo {
                    InfoDetailView(info: info)
                }
            }
        }
    }
    
    private func setAppearance(darkMode: Bool) {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        }
        #endif
        
        // macOS 會自動套用 @AppStorage("isDarkMode") 的值
    }
}

struct InfoContent: Identifiable {
    var id = UUID()
    var title: String
    var content: String
    var icon: String
    var color: Color
}

let infoContents = [
    InfoContent(
        title: "四大習慣養成法則",
        content: """
        《原子習慣》提出了四大習慣法則，可以幫助你更容易養成良好習慣：

        1. 讓習慣變得明顯
        • 時間地點計劃：「我會在[時間]於[地點][行動]」
        • 習慣疊加：在現有習慣之後添加新習慣
        • 環境設計：在環境中放置線索

        2. 讓習慣變得有吸引力
        • 與期待配對：將你「需要」做的事與你「想要」做的事配對
        • 加入社群：與同樣擁有該習慣的人相處
        • 重新思考：專注於習慣的好處而非困難

        3. 讓習慣變得簡單
        • 減少阻力：事先準備環境，降低行動門檻
        • 兩分鐘法則：將習慣簡化到兩分鐘內能完成
        • 一次性決策：提前做決定，避免重複意志力消耗

        4. 讓習慣變得令人滿足
        • 即時獎勵：習慣後立即給自己小獎勵
        • 習慣追蹤：用視覺方式記錄進度
        • 絕不錯過兩次：偶爾錯過一次沒關係，但不要連續錯過
        """,
        icon: "book.fill",
        color: .blue
    ),
    InfoContent(
        title: "身份轉變",
        content: """
        習慣養成的核心是身份的轉變，而非單純的目標達成。

        目標導向的問題：
        • 達成目標後，動力消失
        • 達不成目標時，容易氣餒放棄
        • 只關注結果，忽視過程

        身份導向的好處：
        • 專注於「成為什麼樣的人」
        • 每次行動都是身份的證明
        • 持續的動力來源

        轉變方式：
        1. 決定你想成為什麼樣的人
        2. 通過小勝利證明這一身份
        3. 從「我在嘗試...」轉變為「我是...」

        例如，不是「我想戒煙」，而是「我不是抽煙的人」；不是「我要減肥」，而是「我是一個健康飲食的人」。
        """,
        icon: "person.fill",
        color: .orange
    ),
    InfoContent(
        title: "習慣記分卡",
        content: """
        習慣記分卡是觀察和改變習慣的強大工具。

        步驟一：列出你的習慣
        • 寫下你的日常習慣
        • 標記它們是好習慣、壞習慣還是中性習慣

        步驟二：分析四大法則
        對每個習慣評分（從1-10）：
        • 明顯性：這個習慣的線索有多明顯？
        • 吸引力：你有多期待這個習慣？
        • 簡單性：這個習慣有多容易執行？
        • 滿足感：這個習慣帶來的獎勵有多令人滿足？

        步驟三：制定改進計劃
        • 強化好習慣：增加四個方面的分數
        • 破解壞習慣：降低四個方面的分數

        習慣記分卡幫助你從被動接受轉為主動設計你的習慣系統。
        """,
        icon: "list.bullet.clipboard",
        color: .green
    ),
    InfoContent(
        title: "習慣堆疊",
        content: """
        習慣堆疊是將新習慣融入現有生活的有效方法。

        基本公式：
        「在[現有習慣]之後，我會[新習慣]」

        例如：
        • 在刷牙後，我會冥想一分鐘
        • 在喝完早晨第一杯水後，我會寫下三件感恩的事
        • 在脫鞋進家門後，我會立即整理五分鐘

        進階堆疊：
        你可以創建多重習慣堆疊，形成整個例行流程：
        • 早晨例行：起床→喝水→冥想→寫日記→運動
        • 工作例行：到辦公室→整理桌面→檢查計劃→處理最重要任務
        • 睡前例行：關電子設備→閱讀→反思一天→準備明天衣物

        關鍵是選擇合適的觸發點，確保新舊習慣有自然連接。
        """,
        icon: "square.stack.3d.up.fill",
        color: .purple
    ),
    InfoContent(
        title: "環境設計",
        content: """
        環境是影響習慣形成的強大力量，學會設計你的環境可以大幅提高成功率。

        建立好習慣的環境設計：
        • 線索明顯化：將習慣所需物品放在顯眼處
        • 減少阻力：事先準備好所需工具
        • 一次性決策：提前設置環境，減少每次決策

        例如：
        • 想多喝水：在各個房間放水杯
        • 想多運動：睡前準備好運動服和鞋
        • 想多看書：在沙發旁放一本書
        • 想少用手機：將社交軟件從手機移到平板

        打破壞習慣的環境設計：
        • 增加阻力：為壞習慣添加障礙
        • 減少線索：移除環境中的誘惑
        • 使用拘束裝置：限制自己的特定行為

        例如：
        • 少看電視：將遙控器放在不同房間
        • 少玩手機：使用限制應用使用的軟件
        • 少吃零食：不要在家中存放
        """,
        icon: "house.fill",
        color: .red
    ),
    InfoContent(
        title: "關於原子習慣",
        content: """
        《原子習慣》是由詹姆斯·克利爾(James Clear)撰寫的一本暢銷書，提供了養成好習慣和打破壞習慣的實用框架。

        核心理念：
        微小的改變，驚人的結果。就像原子是構成物質的基本單位，細小的習慣是構建卓越人生的基礎。

        1% 改進法則：
        每天進步1%，一年後你將變得比原來好37倍；每天退步1%，一年後你只剩下原來的3%。

        習慣四法則：
        1. 讓習慣變得明顯（線索）
        2. 讓習慣變得有吸引力（渴望）
        3. 讓習慣變得簡單（回應）
        4. 讓習慣變得令人滿足（獎勵）

        打破壞習慣使用相反法則：
        1. 讓壞習慣變得不明顯
        2. 讓壞習慣變得沒吸引力
        3. 讓壞習慣變得困難
        4. 讓壞習慣變得不滿足

        本應用基於《原子習慣》的理念設計，幫助你更容易地建立和維持良好習慣。
        """,
        icon: "info.circle.fill",
        color: .blue
    )
]

struct InfoDetailView: View {
    var info: InfoContent
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: info.icon)
                            .font(.system(size: 24))
                            .foregroundColor(info.color)
                        
                        Text(info.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 10)
                    
                    Text(info.content)
                        .font(.body)
                        .lineSpacing(6)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("", displayMode: .inline)
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
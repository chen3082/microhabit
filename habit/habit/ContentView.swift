//
//  ContentView.swift
//  habit
//
//  Created by 陳大帥 on 3/25/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var habitStore = HabitStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("今日", systemImage: "calendar")
                }
                .tag(0)
            
            HabitsView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("習慣", systemImage: "list.bullet")
                }
                .tag(1)
            
            StatsView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
        .onAppear {
            // 設置標籤欄外觀
            #if canImport(UIKit) && !targetEnvironment(macCatalyst)
            if #available(iOS 13.0, *) {
                UITabBar.appearance().backgroundColor = .systemBackground
                UITabBar.appearance().unselectedItemTintColor = .systemGray2
            }
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

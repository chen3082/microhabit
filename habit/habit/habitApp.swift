//
//  habitApp.swift
//  habit
//
//  Created by 陳大帥 on 3/25/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@main
struct habitApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    setAppearance(darkMode: isDarkMode)
                }
        }
    }
    
    private func setAppearance(darkMode: Bool) {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        }
        #endif
        // macOS 會自動套用 preferredColorScheme
    }
}

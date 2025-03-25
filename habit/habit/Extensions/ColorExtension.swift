import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    static var systemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    static var secondarySystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    static var systemGray2: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray2)
        #else
        return Color(NSColor.secondaryLabelColor)
        #endif
    }
    
    static var systemGray4: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray4)
        #else
        return Color(NSColor.tertiaryLabelColor)
        #endif
    }
    
    static var systemGray5: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray5)
        #else
        return Color(NSColor.lightGray)
        #endif
    }
    
    static var systemGray6: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.controlColor)
        #endif
    }
} 
import SwiftUI

struct Theme {
    // Base
    static let background = Color(hue: 240/360, saturation: 0.10, brightness: 0.08)
    static let foreground = Color(hue: 0.00, saturation: 0.00, brightness: 0.98)
    static let secondary = Color(hue: 240/360, saturation: 0.10, brightness: 0.16)
    static let muted = Color(hue: 240/360, saturation: 0.10, brightness: 0.16)
    static let mutedForeground = Color(hue: 240/360, saturation: 0.05, brightness: 0.64)

    // Card layers
    static let card = Color(hue: 240/360, saturation: 0.10, brightness: 0.12)
    static let cardElevated = Color(hue: 240/360, saturation: 0.10, brightness: 0.18)

    // Party colors
    static let partyPurple = Color(hue: 270/360, saturation: 0.91, brightness: 0.65)
    static let partyPink = Color(hue: 330/360, saturation: 0.81, brightness: 0.60)
    static let partyBlue = Color(hue: 240/360, saturation: 1.00, brightness: 0.70)
    static let partyGlow = Color(hue: 270/360, saturation: 0.91, brightness: 0.65).opacity(0.4)

    // Gradients
    static let gradientParty = LinearGradient(
        colors: [partyPurple, partyPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientRoom = LinearGradient(
        colors: [partyBlue, partyPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientGlow = RadialGradient(
        gradient: Gradient(colors: [partyGlow, .clear]),
        center: .center,
        startRadius: 0,
        endRadius: 200
    )
}


import SwiftUI

enum PartyButtonVariant {
    case primary, secondary, join, create
}

enum PartyButtonSize {
    case small, medium, large
}

struct PartyButton: View {
    let title: String
    let variant: PartyButtonVariant
    let size: PartyButtonSize
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(padding)
                .frame(maxWidth: .infinity)
                .background(background)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: glowColor, radius: glowRadius)
                .scaleEffect(disabled ? 1.0 : 1.03)
                .animation(.easeInOut(duration: 0.3), value: disabled)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }

    private var padding: EdgeInsets {
        switch size {
        case .small:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large:
            return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary, .create:
            LinearGradient(colors: [Theme.partyPurple, Theme.partyPink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .join:
            Theme.partyBlue
        case .secondary:
            Theme.secondary
        }
    }

    private var glowColor: Color {
        switch variant {
        case .primary, .create:
            return Theme.partyPurple.opacity(0.4)
        case .join:
            return Theme.partyBlue.opacity(0.3)
        case .secondary:
            return .clear
        }
    }

    private var glowRadius: CGFloat {
        switch variant {
        case .primary, .create:
            return 10
        case .join:
            return 6
        case .secondary:
            return 0
        }
    }
}

//  PartyButton.swift
//  Nuvora
//
//  Created by Kenny Pierrot on 15/07/2025.
//


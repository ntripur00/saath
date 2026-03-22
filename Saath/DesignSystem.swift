import SwiftUI

// MARK: - Design System (DS)

struct DS {
    // Brand
    static let primary      = Color(hex: "0D9488")   // Teal 600
    static let primaryLight = Color(hex: "CCFBF1")   // Teal 100
    static let primaryDark  = Color(hex: "0F766E")   // Teal 700
    static let accent = Color(hex: "4FD1C5")   // Teal 300 (light mint)

    static let secondary    = Color(hex: "F97316")   // Orange 500
    static let secondaryLight = Color(hex: "FFEDD5") // Orange 100

    // UI
    static let background   = Color(hex: "F9FAFB")
    static let surface      = Color.white
    static let surfaceSecondary = Color(hex: "F3F4F6")

    // Text
    static let textPrimary  = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary  = Color(hex: "9CA3AF")

    // Semantic
    static let border       = Color(hex: "E5E7EB")
    static let borderFocus  = Color(hex: "0D9488").opacity(0.4)
    static let success      = Color(hex: "10B981")
    static let danger       = Color(hex: "EF4444")
    static let warning      = Color(hex: "F59E0B")

    // Child avatar colors
    static let blue         = Color(hex: "3B82F6")
    static let pink         = Color(hex: "EC4899")
    static let purple       = Color(hex: "8B5CF6")

    // Spacing
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32

    // Radius
    static let radiusSm:  CGFloat = 8
    static let radiusMd:  CGFloat = 12
    static let radiusLg:  CGFloat = 16
    static let radiusXl:  CGFloat = 24
}

// MARK: - Color Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - View Modifiers

struct SurfaceCard: ViewModifier {
    var radius: CGFloat  = DS.radiusLg
    var padding: CGFloat = DS.md
    var shadow: Bool     = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(shadow ? 0.04 : 0), radius: 8, x: 0, y: 2)
    }
}

struct PrimaryButton: ViewModifier {
    var disabled: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(disabled ? DS.primary.opacity(0.4) : DS.primary)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
    }
}

extension View {
    func surfaceCard(radius: CGFloat = DS.radiusLg,
                     padding: CGFloat = DS.md,
                     shadow: Bool = true) -> some View {
        modifier(SurfaceCard(radius: radius, padding: padding, shadow: shadow))
    }

    func primaryButton(disabled: Bool = false) -> some View {
        modifier(PrimaryButton(disabled: disabled))
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .kerning(1.2)
            .foregroundColor(DS.textSecondary)
    }
}

// MARK: - Pill Badge

struct PillBadge: View {
    let text: String
    var color: Color = DS.primary
    var small: Bool  = false

    var body: some View {
        Text(text)
            .font(.system(size: small ? 10 : 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, small ? 6 : 8)
            .padding(.vertical, small ? 3 : 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Avatar Circle

struct AvatarView: View {
    let initial: String
    var color: Color    = DS.primary
    var size: CGFloat   = 44
    var isActive: Bool  = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(isActive ? color : Color.clear, lineWidth: 2)
                )

            Text(initial)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Input Field

struct SaathInputField: View {
    let label: String
    var icon: String? = nil
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label)
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(DS.textTertiary)
                        .frame(width: 20)
                }
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .keyboardType(keyboard)
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 13)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Claim Button

struct ClaimButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 12))
                Text("I'll handle this")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(DS.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(DS.primaryLight)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Claimed Badge (tappable to unclaim)

struct ClaimedBadge: View {
    let name: String?
    var onUnclaim: (() -> Void)? = nil

    @State private var showUnclaim = false

    var body: some View {
        Button {
            if onUnclaim != nil { showUnclaim = true }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("Handled by \(name ?? "you")")
                    .font(.system(size: 12, weight: .semibold))
                if onUnclaim != nil {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .opacity(0.6)
                }
            }
            .foregroundColor(DS.success)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DS.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Unmark as handled?",
            isPresented: $showUnclaim,
            titleVisibility: .visible
        ) {
            Button("Unclaim Event", role: .destructive) { onUnclaim?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the Handled status so someone can claim it again.")
        }
    }
}

// MARK: - Category Dot

struct CategoryDot: View {
    let color: Color
    var size: CGFloat = 10

    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String   = ""

    var body: some View {
        VStack(spacing: DS.md) {
            Spacer()
            ZStack {
                Circle()
                    .fill(DS.primaryLight)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(DS.primary)
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DS.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.xl)

            if let action, !actionLabel.isEmpty {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, DS.xl)
                        .padding(.vertical, 12)
                        .background(DS.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, DS.sm)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Divider

struct SDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.border)
            .frame(height: 1)
    }
}

import SwiftUI
import UIKit

// MARK: - Haptics Helper

struct Haptics {
    static func light()    { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()   { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()    { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error()    { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Onboarding State

enum OnboardingStep {
    case welcome, role, addChildren, loading
}

enum HouseholdRole {
    case setup, join
}

// MARK: - OnboardingView (coordinator)

struct OnboardingView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var auth:  AuthService
    var onComplete: () -> Void

    @State private var step:          OnboardingStep = .welcome
    @State private var role:          HouseholdRole  = .setup
    @State private var joinCode:      String         = ""
    @State private var children:      [DraftChild]   = [DraftChild()]
    @State private var loadingDone    = false

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeScreen(name: auth.currentUser?.displayName ?? "")
                    .transition(.asymmetric(
                        insertion:  .opacity,
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))
                    .onAppear {
                        // Auto-advance after 2.2s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                step = .role
                            }
                            Haptics.light()
                        }
                    }

            case .role:
                RoleScreen(role: $role, joinCode: $joinCode) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = .addChildren
                    }
                    Haptics.medium()
                }
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .addChildren:
                AddChildrenScreen(children: $children) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = .loading
                    }
                    Haptics.medium()
                } onBack: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = .role
                    }
                    Haptics.light()
                }
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .loading:
                LoadingScreen(children: children) {
                    // Commit data
                    commitData()
                    onComplete()
                }
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .opacity
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: step)
    }

    private func commitData() {
        // Save children to store (clearing any sample data)
        store.children = []
        store.events   = []

        for (i, draft) in children.enumerated() {
            let trimmed = draft.name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            store.addChild(name: trimmed, dob: draft.dob, gender: draft.gender)
        }

        // Handle join flow
        if role == .join && !joinCode.isEmpty {
            _ = store.joinHousehold(code: joinCode)
        }

        store.hasCompletedOnboarding = true
    }
}

// MARK: - Draft Child (temporary onboarding model)

struct DraftChild: Identifiable {
    var id    = UUID()
    var name  = ""
    var dob   = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
    var gender = "Female"

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
}

// ─────────────────────────────────────────────
// MARK: - Screen 1: Welcome
// ─────────────────────────────────────────────

struct WelcomeScreen: View {
    let name: String
    @State private var logoScale:   CGFloat = 0.4
    @State private var logoOpacity: Double  = 0
    @State private var textOpacity: Double  = 0
    @State private var ringScale:   CGFloat = 0.6
    @State private var pulseOpacity: Double = 0

    private var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var body: some View {
        ZStack {
            // Subtle background rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(DS.primary.opacity(0.06 - Double(i) * 0.015), lineWidth: 1)
                    .frame(width: CGFloat(180 + i * 80), height: CGFloat(180 + i * 80))
                    .scaleEffect(ringScale)
                    .opacity(pulseOpacity)
            }

            VStack(spacing: 28) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DS.primary, DS.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: DS.primary.opacity(0.35), radius: 24, x: 0, y: 10)

                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 46))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Text
                VStack(spacing: 10) {
                    Text("Welcome\(firstName.isEmpty ? "" : ", \(firstName)") 👋")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Let's set up your family in\njust a few steps.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(textOpacity)

                Spacer()
                Spacer()

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Capsule()
                            .fill(idx == 0 ? DS.primary : DS.border)
                            .frame(width: idx == 0 ? 24 : 8, height: 8)
                    }
                }
                .opacity(textOpacity)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, DS.lg)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                logoScale   = 1.0
                logoOpacity = 1.0
                ringScale   = 1.0
                pulseOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                textOpacity = 1.0
            }
            Haptics.success()
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Screen 2: Role Selection
// ─────────────────────────────────────────────

struct RoleScreen: View {
    @Binding var role:     HouseholdRole
    @Binding var joinCode: String
    let onContinue: () -> Void

    @State private var appear = false

    var canContinue: Bool {
        role == .setup || (role == .join && joinCode.count >= 12)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Text("How are you joining?")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Text("Choose how you'd like to use Saath")
                    .font(.system(size: 15))
                    .foregroundColor(DS.textSecondary)
            }
            .padding(.top, 64)
            .padding(.horizontal, DS.lg)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            Spacer()

            // Role cards
            VStack(spacing: DS.md) {
                RoleCard(
                    icon:     "house.fill",
                    emoji:    "🏠",
                    title:    "Set up our household",
                    subtitle: "I'm the first parent joining — I'll invite my partner",
                    selected: role == .setup,
                    color:    DS.primary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { role = .setup }
                    Haptics.selection()
                }

                RoleCard(
                    icon:     "link.circle.fill",
                    emoji:    "🔗",
                    title:    "Join my partner's household",
                    subtitle: "My partner already set up Saath — I have their code",
                    selected: role == .join,
                    color:    DS.secondary
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { role = .join }
                    Haptics.selection()
                }

                // Join code field
                if role == .join {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "number.square.fill")
                                .foregroundColor(DS.textTertiary)
                            TextField("Partner's code  e.g. SAATH-ABC123", text: $joinCode)
                                .font(.system(size: 15, design: .monospaced))
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                        }
                        .padding(DS.md)
                        .background(DS.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                .stroke(DS.secondary.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: role)
                }
            }
            .padding(.horizontal, DS.lg)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 30)

            Spacer()

            // Continue
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .primaryButton(disabled: !canContinue)
                }
                .disabled(!canContinue)

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Capsule()
                            .fill(idx == 1 ? DS.primary : DS.border)
                            .frame(width: idx == 1 ? 24 : 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, DS.lg)
            .padding(.bottom, 48)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let icon:     String
    let emoji:    String
    let title:    String
    let subtitle: String
    let selected: Bool
    let color:    Color
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                        .fill(selected ? color.opacity(0.15) : DS.surfaceSecondary)
                        .frame(width: 52, height: 52)
                    Text(emoji)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DS.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(DS.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(selected ? color : DS.border, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(color)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(DS.md)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous)
                    .stroke(selected ? color.opacity(0.5) : DS.border,
                            lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? color.opacity(0.12) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
    }
}

// ─────────────────────────────────────────────
// MARK: - Screen 3: Add Children
// ─────────────────────────────────────────────

struct AddChildrenScreen: View {
    @Binding var children: [DraftChild]
    let onContinue: () -> Void
    let onBack:     () -> Void

    @State private var appear       = false
    @State private var activeIndex  = 0

    private var canContinue: Bool {
        children.contains { $0.isValid }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header + back
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.primary)
                        .frame(width: 36, height: 36)
                        .background(DS.primaryLight)
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, DS.lg)
            .padding(.top, 56)

            VStack(spacing: 8) {
                Text("Tell us about\nyour children")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                Text("You can always add more later")
                    .font(.system(size: 15))
                    .foregroundColor(DS.textSecondary)
            }
            .padding(.top, DS.md)
            .padding(.horizontal, DS.lg)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 16)

            // Child cards — scrollable
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.md) {
                    ForEach(children.indices, id: \.self) { i in
                        DraftChildCard(
                            child:   $children[i],
                            index:   i,
                            canDelete: children.count > 1
                        ) {
                            children.remove(at: i)
                            Haptics.medium()
                        }
                    }

                    // Add another child
                    if children.count < 6 {
                        Button {
                            children.append(DraftChild())
                            Haptics.light()
                        } label: {
                            HStack(spacing: DS.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Add another child")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(DS.primary)
                            .frame(maxWidth: .infinity)
                            .padding(DS.md)
                            .background(DS.primaryLight)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous)
                                    .stroke(DS.primary.opacity(0.2), lineWidth: 1.5)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.lg)
                .padding(.vertical, DS.md)
            }
            .opacity(appear ? 1 : 0)

            // Continue
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .primaryButton(disabled: !canContinue)
                }
                .disabled(!canContinue)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Capsule()
                            .fill(idx == 2 ? DS.primary : DS.border)
                            .frame(width: idx == 2 ? 24 : 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, DS.lg)
            .padding(.bottom, 48)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }
}

// MARK: - Draft Child Card

struct DraftChildCard: View {
    @Binding var child: DraftChild
    let index:     Int
    let canDelete: Bool
    let onDelete:  () -> Void

    private let genders = ["Female", "Male", "Other"]

    private func colorFor(_ g: String) -> Color {
        switch g {
        case "Male":   return DS.blue
        case "Female": return DS.pink
        default:       return DS.purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            // Card header
            HStack {
                AvatarView(
                    initial: child.name.isEmpty ? "\(index + 1)" : String(child.name.prefix(1)).uppercased(),
                    color: colorFor(child.gender),
                    size: 38
                )
                Text(child.name.isEmpty ? "Child \(index + 1)" : child.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(child.name.isEmpty ? DS.textTertiary : DS.textPrimary)
                Spacer()
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DS.textTertiary)
                    }
                }
            }

            // Name field
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundColor(DS.textTertiary)
                    .frame(width: 20)
                TextField("Child's name", text: $child.name)
                    .font(.system(size: 15))
                    .onChange(of: child.name) { _, _ in Haptics.selection() }
            }
            .padding(DS.md)
            .background(DS.background)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )

            // DOB
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(DS.textTertiary)
                    .frame(width: 20)
                DatePicker("", selection: $child.dob, in: ...Date(),
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(DS.primary)
            }
            .padding(DS.md)
            .background(DS.background)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )

            // Gender
            HStack(spacing: DS.sm) {
                ForEach(genders, id: \.self) { g in
                    Button {
                        child.gender = g
                        Haptics.selection()
                    } label: {
                        Text(g)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(child.gender == g ? .white : DS.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(child.gender == g ? colorFor(g) : DS.background)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: child.gender)
                }
            }
        }
        .padding(DS.md)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusXl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusXl, style: .continuous)
                .stroke(DS.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// ─────────────────────────────────────────────
// MARK: - Screen 4: Loading / Celebration
// ─────────────────────────────────────────────

struct LoadingScreen: View {
    let children:   [DraftChild]
    let onComplete: () -> Void

    @State private var progress:      CGFloat = 0
    @State private var tipIndex       = 0
    @State private var checkScale:    CGFloat = 0
    @State private var checkOpacity:  Double  = 0
    @State private var showCheck      = false
    @State private var confettiItems: [ConfettiItem] = []

    private let tips = [
        "Setting up your family calendar…",
        "Creating your household profile…",
        "Getting everything ready for you…",
        "Almost there — just a moment…",
        "Your family space is ready! 🎉"
    ]

    private let totalDuration: Double = 3.5

    var firstChildName: String {
        children.first(where: { $0.isValid })?.name ?? "your family"
    }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()

            // Confetti
            ForEach(confettiItems) { item in
                ConfettiPiece(item: item)
            }

            VStack(spacing: 0) {
                Spacer()

                if showCheck {
                    // ── Celebration state ──
                    VStack(spacing: DS.lg) {
                        ZStack {
                            Circle()
                                .fill(DS.primaryLight)
                                .frame(width: 110, height: 110)
                            Image(systemName: "checkmark")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(DS.primary)
                        }
                        .scaleEffect(checkScale)
                        .opacity(checkOpacity)

                        VStack(spacing: 8) {
                            Text("You're all set! 🎉")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundColor(DS.textPrimary)
                            Text("Welcome to Saath, \(firstChildName)'s family")
                                .font(.system(size: 16))
                                .foregroundColor(DS.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(checkOpacity)
                    }
                } else {
                    // ── Loading state ──
                    VStack(spacing: 32) {
                        // Animated logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [DS.primary, DS.primaryDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: DS.primary.opacity(0.3), radius: 16, x: 0, y: 6)

                            Image(systemName: "figure.2.and.child.holdinghands")
                                .font(.system(size: 38))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: DS.md) {
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(DS.border)
                                        .frame(height: 6)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [DS.primary, DS.accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * progress, height: 6)
                                        .animation(.easeInOut(duration: 0.4), value: progress)
                                }
                            }
                            .frame(height: 6)
                            .padding(.horizontal, DS.xl)

                            // Tip text
                            Text(tips[min(tipIndex, tips.count - 1)])
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(DS.textSecondary)
                                .multilineTextAlignment(.center)
                                .id(tipIndex)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .animation(.easeInOut(duration: 0.4), value: tipIndex)

                            // Percentage
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(DS.textTertiary)
                        }
                    }
                    .padding(.horizontal, DS.lg)
                }

                Spacer()
            }
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        // Animate progress in steps
        let steps: [(delay: Double, value: CGFloat, tip: Int)] = [
            (0.3,  0.2,  0),
            (0.8,  0.45, 1),
            (1.4,  0.65, 2),
            (2.0,  0.82, 3),
            (2.6,  1.0,  4),
        ]

        for step in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                withAnimation { progress = step.value }
                tipIndex = step.tip
                Haptics.light()
            }
        }

        // Show celebration at end
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheck    = true
                checkScale   = 1.0
                checkOpacity = 1.0
            }
            Haptics.success()
            spawnConfetti()
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            Haptics.medium()
            onComplete()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [DS.primary, DS.secondary, DS.accent, .pink, .yellow, .green]
        confettiItems = (0..<40).map { i in
            ConfettiItem(
                id:     i,
                color:  colors[i % colors.count],
                x:      CGFloat.random(in: 0...1),
                delay:  Double.random(in: 0...0.5),
                size:   CGFloat.random(in: 6...14),
                angle:  Double.random(in: 0...360)
            )
        }
    }
}

// MARK: - Confetti

struct ConfettiItem: Identifiable {
    let id:    Int
    let color: Color
    let x:     CGFloat
    let delay: Double
    let size:  CGFloat
    let angle: Double
}

struct ConfettiPiece: View {
    let item: ConfettiItem
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 1

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(item.color)
                .frame(width: item.size, height: item.size * 0.5)
                .rotationEffect(.degrees(item.angle))
                .position(
                    x: geo.size.width * item.x,
                    y: offset
                )
                .opacity(opacity)
                .onAppear {
                    withAnimation(
                        .easeIn(duration: 1.8)
                        .delay(item.delay)
                    ) {
                        offset  = geo.size.height + 50
                        opacity = 0
                    }
                }
        }
    }
}

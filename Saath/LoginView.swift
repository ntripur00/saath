import SwiftUI
import AuthenticationServices


struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DS.primary.opacity(0.08),
                    DS.background,
                    DS.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo & Hero ──
                VStack(spacing: DS.lg) {
                    // App icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DS.primary, DS.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)
                            .shadow(color: DS.primary.opacity(0.3), radius: 20, x: 0, y: 8)

                        Image(systemName: "figure.2.and.child.holdinghands")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.7)
                    .opacity(animateIn ? 1 : 0)

                    // Title
                    VStack(spacing: 6) {
                        Text("Saath")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundColor(DS.textPrimary)

                        Text("Parenting, together.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DS.textSecondary)
                    }
                    .offset(y: animateIn ? 0 : 20)
                    .opacity(animateIn ? 1 : 0)

                    // Feature pills
                    HStack(spacing: DS.sm) {
                        FeaturePill(icon: "calendar.badge.checkmark", text: "Shared Calendar")
                        FeaturePill(icon: "person.2.fill",            text: "Co-parenting")
                        FeaturePill(icon: "bell.badge.fill",          text: "Reminders")
                    }
                    .offset(y: animateIn ? 0 : 20)
                    .opacity(animateIn ? 1 : 0)
                }

                Spacer()
                Spacer()

                // ── Sign-In Buttons ──
                VStack(spacing: DS.md) {

                    // Error message
                    if let error = auth.errorMessage {
                        HStack(spacing: DS.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DS.warning)
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(DS.textSecondary)
                        }
                        .padding(DS.md)
                        .background(DS.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if auth.isLoading {
                        ProgressView()
                            .tint(DS.primary)
                            .scaleEffect(1.2)
                            .frame(height: 52)
                    } else {
                        // Google Sign-In
                        Button {
                            Task { await auth.signInWithGoogle() }
                        } label: {
                            HStack(spacing: DS.md) {
                                // Google "G" logo
                                GoogleGLogo()
                                    .frame(width: 22, height: 22)

                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DS.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(DS.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                    .stroke(DS.border, lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        // Apple Sign-In
                        SignInWithAppleButton(.continue) { request in
                            let appleRequest = auth.appleSignInRequest()
                            request.requestedScopes     = appleRequest.requestedScopes
                            request.nonce               = appleRequest.nonce
                        } onCompletion: { result in
                            Task { await auth.handleAppleSignIn(result: result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                    }

                    // Privacy note
                    Text("By continuing, you agree to our Terms & Privacy Policy.\nWe never share your data.")
                        .font(.system(size: 11))
                        .foregroundColor(DS.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, DS.xs)
                }
                .padding(.horizontal, DS.lg)
                .offset(y: animateIn ? 0 : 30)
                .opacity(animateIn ? 1 : 0)

                Spacer().frame(height: DS.xl)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
        .animation(.easeInOut, value: auth.errorMessage)
    }
}

// MARK: - Feature Pill

struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(DS.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DS.primaryLight)
        .clipShape(Capsule())
    }
}

// MARK: - Google G Logo (drawn, no asset needed)

struct GoogleGLogo: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w / 2, cy = h / 2, r = min(w, h) / 2

            // Outer circle clip
            let circle = Path(ellipseIn: CGRect(x: 0, y: 0, width: w, height: h))

            // Blue arc (top-right)
            ctx.fill(arc(cx: cx, cy: cy, r: r, from: -23, to: 90), with: .color(.blue))
            // Red arc (top-left)
            ctx.fill(arc(cx: cx, cy: cy, r: r, from: 90, to: 210), with: .color(.red))
            // Yellow arc (bottom-left)
            ctx.fill(arc(cx: cx, cy: cy, r: r, from: 210, to: 330), with: .color(Color(hex: "FBBC05")))
            // Green arc (bottom-right)
            ctx.fill(arc(cx: cx, cy: cy, r: r, from: 330, to: 360 - 23), with: .color(.green))

            // White inner circle
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - r*0.55, y: cy - r*0.55,
                                       width: r*1.1, height: r*1.1)),
                with: .color(.white)
            )

            // Blue "G" bar
            var bar = Path()
            bar.addRect(CGRect(x: cx - 0.05*w, y: cy - 0.12*h, width: 0.55*w, height: 0.24*h))
            ctx.clip(to: circle)
            ctx.fill(bar, with: .color(.blue))
        }
    }

    private func arc(cx: CGFloat, cy: CGFloat, r: CGFloat,
                     from: CGFloat, to: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                 startAngle: .degrees(from), endAngle: .degrees(to),
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}

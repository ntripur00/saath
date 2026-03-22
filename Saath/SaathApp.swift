import SwiftUI
import FirebaseCore

@main
struct SaathApp: App {
    @StateObject private var auth    = AuthService.shared
    @StateObject private var store   = DataStore()
    @StateObject private var calSync = CalendarSyncService.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootGatekeeper()
                .environmentObject(auth)
                .environmentObject(store)
                .environmentObject(calSync)
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Root Gatekeeper
// Flow: Login → Onboarding (first time) → App

struct RootGatekeeper: View {
    @EnvironmentObject var auth:  AuthService
    @EnvironmentObject var store: DataStore

    var body: some View {
        Group {
            if auth.currentUser == nil {
                // Not logged in → Login screen
                LoginView()
                    .transition(.opacity)

            } else if !store.hasCompletedOnboarding {
                // Logged in, first time → Onboarding wizard
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        store.hasCompletedOnboarding = true
                    }
                    Haptics.success()
                }
                .transition(.opacity)

            } else {
                // Logged in + onboarded → Main app
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: auth.currentUser?.uid)
        .animation(.easeInOut(duration: 0.4), value: store.hasCompletedOnboarding)
    }
}

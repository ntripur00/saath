import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedTab  = 0
    @State private var showAddEvent = false
    @State private var showAddChild = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack { HomeView() }
                    .tag(0)

                NavigationStack { CalendarView() }
                    .tag(1)

                NavigationStack { ChildrenView() }
                    .tag(2)

                NavigationStack {
                    PlaceholderView(
                        icon: "folder.badge.plus",
                        title: "Records",
                        subtitle: "Medical records, documents & shared files\ncoming soon."
                    )
                    .navigationTitle("Records")
                }
                .tag(3)

                NavigationStack { SettingsView() }
                    .tag(4)
            }
            .tint(DS.primary)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab,
                         showAddEvent: $showAddEvent,
                         showAddChild: $showAddChild)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddEvent) {
            NavigationStack { EventFormView() }
        }
        .sheet(isPresented: $showAddChild) {
            NavigationStack { AddChildView() }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedTab:  Int
    @Binding var showAddEvent: Bool
    @Binding var showAddChild: Bool

    private let items: [(icon: String, activeIcon: String, label: String)] = [
        ("house",                 "house.fill",                  "Home"),
        ("calendar",              "calendar.circle.fill",        "Calendar"),
        ("person.2",              "person.2.fill",               "Children"),
        ("folder",                "folder.fill",                 "Records"),
        ("gearshape",             "gearshape.fill",              "Settings"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            SDivider()

            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { i in
                    // FAB slot between Children and Records
                    if i == 3 {
                        Spacer()
                        fabButton
                        Spacer()
                    }

                    tabItem(index: i)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
        }
    }

    private func tabItem(index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == index
                      ? items[index].activeIcon
                      : items[index].icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? DS.primary : DS.textTertiary)
                    .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                Text(items[index].label)
                    .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? DS.primary : DS.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var fabButton: some View {
        Button {
            if selectedTab == 1      { showAddEvent = true }
            else if selectedTab == 2 { showAddChild = true }
            else                     { showAddEvent = true }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.primary, DS.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: DS.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -16)
    }
}

// MARK: - Placeholder

struct PlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        EmptyStateView(icon: icon, title: title, subtitle: subtitle)
            .background(DS.background)
    }
}

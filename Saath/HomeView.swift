import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @State private var filter: EventFilter = .all
    @State private var showAddEvent = false
    @State private var showAddChild = false

    // Greeting
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "Good Morning ☀️" : h < 17 ? "Good Afternoon 👋" : "Good Evening 🌙"
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Top Header ──
                headerSection
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.md)

                // ── Stats Row ──
                statsRow
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.lg)

                // ── Filter Chips ──
                filterChips
                    .padding(.top, DS.lg)

                // ── Daily Insight ──
                insightCard
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.lg)

                // ── Today's Events ──
                VStack(alignment: .leading, spacing: DS.md) {
                    HStack {
                        SectionLabel(text: "Today's Schedule")
                        Spacer()
                        let count = store.todayEvents(filter: filter).count
                        if count > 0 {
                            Text("\(count) event\(count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(DS.textSecondary)
                        }
                    }

                    let todayEvts = store.todayEvents(filter: filter)
                    if todayEvts.isEmpty {
                        emptyEventsCard
                    } else {
                        ForEach(todayEvts) { event in
                            NavigationLink(destination: EventFormView(event: event)) {
                                HomeEventCard(event: event) {
                                    store.claimEvent(id: event.id)
                                } onUnclaim: {
                                    store.unclaimEvent(id: event.id)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.md)
                .padding(.top, DS.lg)

                // ── Quick Actions ──
                VStack(alignment: .leading, spacing: DS.md) {
                    SectionLabel(text: "Quick Actions")
                    HStack(spacing: DS.md) {
                        QuickAction(icon: "calendar.badge.plus",
                                    label: "Add Event",
                                    color: DS.primary) { showAddEvent = true }
                        QuickAction(icon: "person.badge.plus",
                                    label: "Add Child",
                                    color: DS.secondary) { showAddChild = true }
                    }
                }
                .padding(.horizontal, DS.md)
                .padding(.top, DS.xl)

                Spacer(minLength: 120)
            }
        }
        .background(DS.background)
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddEvent) { NavigationStack { EventFormView() } }
        .sheet(isPresented: $showAddChild) { NavigationStack { AddChildView() } }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Text(todayDateString)
                    .font(.system(size: 14))
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            AvatarView(
                initial: store.currentUser.initial,
                color: DS.primary,
                size: 44
            )
        }
    }

    private var statsRow: some View {
        HStack(spacing: DS.md) {
            StatCard(
                value: "\(store.events.filter { Calendar.current.isDateInToday($0.startTime) }.count)",
                label: "Today",
                icon: "calendar",
                color: DS.primary
            )
            StatCard(
                value: "\(store.children.count)",
                label: "Children",
                icon: "person.2.fill",
                color: DS.secondary
            )
            StatCard(
                value: "\(store.events.filter { $0.isClaimed }.count)",
                label: "Claimed",
                icon: "checkmark.circle.fill",
                color: DS.success
            )
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.sm) {
                Spacer().frame(width: 8)

                FilterChip(label: "All",
                           selected: filter == .all) { filter = .all }
                FilterChip(label: "Family",
                           selected: filter == .family) { filter = .family }

                ForEach(store.children) { child in
                    FilterChip(
                        label: child.name,
                        selected: filter == .child(child.id),
                        color: child.avatarColor
                    ) { filter = .child(child.id) }
                }
                Spacer().frame(width: 8)
            }
        }
    }

    private var insightCard: some View {
        HStack(spacing: DS.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.radiusSm, style: .continuous)
                    .fill(DS.secondaryLight)
                    .frame(width: 44, height: 44)
                Text("💡")
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Insight")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DS.secondary)
                Text("Massage (Maalish) promotes circulation. Use warm natural oils.")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(2)
            }
        }
        .padding(DS.md)
        .background(
            LinearGradient(
                colors: [DS.secondaryLight, DS.secondaryLight.opacity(0.3)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous)
                .stroke(DS.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var emptyEventsCard: some View {
        VStack(spacing: DS.sm) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundColor(DS.primaryLight)
            Text("All clear today!")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DS.textSecondary)
            Text("No events scheduled")
                .font(.system(size: 13))
                .foregroundColor(DS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.xl)
        .surfaceCard()
    }
}

// MARK: - Home Event Card

struct HomeEventCard: View {
    let event: SaathEvent
    let onClaim:   () -> Void
    let onUnclaim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: DS.md) {
                // Color bar + category dot
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(event.isClaimed ? DS.success : event.categoryColor)
                        .frame(width: 4, height: 36)
                    Text(event.categoryEmoji)
                        .font(.system(size: 14))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(event.isClaimed ? DS.textSecondary : DS.textPrimary)
                            .strikethrough(event.isClaimed, color: DS.textSecondary)
                        Spacer()
                        Text(event.timeString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.textTertiary)
                    }

                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DS.textSecondary)
                            .lineLimit(1)
                    }

                    if !event.notes.isEmpty {
                        Text(event.notes)
                            .font(.system(size: 12))
                            .foregroundColor(DS.textTertiary)
                            .lineLimit(1)
                            .italic()
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textTertiary)
            }
            .padding(DS.md)

            if !event.isClaimed {
                SDivider()
                ClaimButton(action: onClaim)
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, DS.sm)
            } else {
                SDivider()
                ClaimedBadge(name: event.claimedBy, onUnclaim: onUnclaim)
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, DS.sm)
            }
        }
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous)
                .stroke(event.isClaimed ? DS.success.opacity(0.3) : DS.border, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon:  String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(DS.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DS.textSecondary)
        }
        .padding(DS.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(DS.border, lineWidth: 1)
        )
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label:    String
    let selected: Bool
    var color:    Color = DS.primary
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : DS.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected
                    ? color
                    : DS.surface
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(selected ? Color.clear : DS.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
    }
}

// MARK: - Quick Action

struct QuickAction: View {
    let icon:   String
    let label:  String
    let color:  Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textTertiary)
            }
            .padding(DS.md)
            .surfaceCard(padding: 0)
        }
        .buttonStyle(.plain)
    }
}

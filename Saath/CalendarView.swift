import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDate   = Date()
    @State private var displayedMonth = Date()
    @State private var showAddEvent   = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Calendar Card ──
                MonthGrid(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    store: store
                )
                .padding(DS.md)

                // ── Day header ──
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel(text: "Schedule")
                        Text(selectedDateFormatted)
                            .font(.system(size: 13))
                            .foregroundColor(DS.textSecondary)
                    }
                    Spacer()
                    let count = store.eventsForDay(selectedDate).count
                    if count > 0 {
                        PillBadge(text: "\(count) event\(count == 1 ? "" : "s")",
                                  color: DS.primary, small: true)
                    }
                }
                .padding(.horizontal, DS.md + 4)
                .padding(.vertical, DS.sm)

                // ── Events ──
                let dayEvents = store.eventsForDay(selectedDate)

                if dayEvents.isEmpty {
                    VStack(spacing: DS.md) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(DS.primaryLight)
                        Text("No events this day")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.textSecondary)
                        Button { showAddEvent = true } label: {
                            Text("Add an event")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.primary)
                        }
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: DS.sm) {
                        ForEach(dayEvents) { event in
                            NavigationLink(destination: EventFormView(event: event)) {
                                CalendarEventRow(event: event) {
                                    store.claimEvent(id: event.id)
                                } onUnclaim: {
                                    store.unclaimEvent(id: event.id)
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.deleteEvent(id: event.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if !event.isClaimed {
                                    Button {
                                        store.claimEvent(id: event.id)
                                    } label: {
                                        Label("Claim", systemImage: "hand.raised.fill")
                                    }
                                    .tint(DS.primary)
                                }
                            }
                        }
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.sm)
                }
            }
        }
        .background(DS.background)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddEvent) { NavigationStack { EventFormView() } }
    }

    private var selectedDateFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: selectedDate)
    }
}

// MARK: - Month Grid

struct MonthGrid: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate:   Date
    let store: DataStore

    private let cal      = Calendar.current
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

    private var headerTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var gridDates: [Date?] {
        let comps    = cal.dateComponents([.year, .month], from: displayedMonth)
        let firstDay = cal.date(from: comps)!
        let offset   = cal.component(.weekday, from: firstDay) - 1
        let count    = cal.range(of: .day, in: .month, for: displayedMonth)!.count
        var grid: [Date?] = Array(repeating: nil, count: offset)
        for d in 0..<count { grid.append(cal.date(byAdding: .day, value: d, to: firstDay)!) }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }

    private var eventDays: Set<Int> {
        let c = cal.dateComponents([.year, .month], from: displayedMonth)
        return store.daysWithEvents(year: c.year!, month: c.month!)
    }

    var body: some View {
        VStack(spacing: DS.md) {
            // Month navigator
            HStack {
                Button { shift(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.primary)
                        .frame(width: 36, height: 36)
                        .background(DS.primaryLight)
                        .clipShape(Circle())
                }
                Spacer()
                Text(headerTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Button { shift(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.primary)
                        .frame(width: 36, height: 36)
                        .background(DS.primaryLight)
                        .clipShape(Circle())
                }
            }

            // Day labels
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayNames[i])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: cols, spacing: 4) {
                ForEach(0..<gridDates.count, id: \.self) { i in
                    if let date = gridDates[i] {
                        let day        = cal.component(.day, from: date)
                        let isToday    = cal.isDateInToday(date)
                        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                        let hasEvent   = eventDays.contains(day)

                        DayCell(day: day, isToday: isToday,
                                isSelected: isSelected, hasEvent: hasEvent) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(DS.md)
        .surfaceCard(radius: DS.radiusXl, padding: 0)
    }

    private func shift(_ n: Int) {
        if let m = cal.date(byAdding: .month, value: n, to: displayedMonth) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                displayedMonth = m
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let day: Int
    let isToday: Bool
    let isSelected: Bool
    let hasEvent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(DS.primary)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .fill(DS.primaryLight)
                            .frame(width: 36, height: 36)
                    }
                    Text("\(day)")
                        .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(
                            isSelected ? .white :
                            isToday    ? DS.primary :
                                         DS.textPrimary
                        )
                }
                // Event indicator
                Circle()
                    .fill(hasEvent
                          ? (isSelected ? Color.white.opacity(0.7) : DS.primary)
                          : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: SaathEvent
    let onClaim:   () -> Void
    let onUnclaim: () -> Void

    private var timeStr: String {
        guard !event.allDay else { return "All\nDay" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: event.startTime)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // Time column
            VStack(spacing: 6) {
                Text(timeStr)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 44)
                CategoryDot(color: event.categoryColor, size: 8)
            }
            .padding(.top, 2)

            // Separator
            Rectangle()
                .fill(event.categoryColor.opacity(0.3))
                .frame(width: 2)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(event.isClaimed ? DS.textSecondary : DS.textPrimary)
                            .strikethrough(event.isClaimed, color: DS.textSecondary)

                        Text(event.category)
                            .font(.system(size: 11))
                            .foregroundColor(event.categoryColor)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
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
                        .font(.system(size: 12).italic())
                        .foregroundColor(DS.textTertiary)
                        .lineLimit(2)
                }

                if event.isClaimed {
                    ClaimedBadge(name: event.claimedBy, onUnclaim: onUnclaim)
                } else {
                    ClaimButton(action: onClaim)
                }
            }
            .padding(.vertical, 12)
            .padding(.trailing, 12)
        }
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                .stroke(event.isClaimed ? DS.success.opacity(0.3) : DS.border, lineWidth: 1)
        )
    }
}

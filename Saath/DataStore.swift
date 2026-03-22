import Foundation
import Combine
import SwiftUI

class DataStore: ObservableObject {

    // MARK: - Published State
    @Published var children:  [Child]       = []
    @Published var events:    [SaathEvent]  = []
    @Published var currentUser: HouseholdMember = HouseholdMember(name: "You", role: "Parent")
    @Published var householdCode: String         = ""
    @Published var linkedMembers: [HouseholdMember] = []
    @Published var pendingPartnerCode: String    = ""
    @Published var hasCompletedOnboarding: Bool  = false

    private let userDefaults = UserDefaults.standard

    // MARK: - Init
    init() {
        loadFromDefaults()
    }

    // MARK: - Persistence
    private func save() {
        if let cd = try? JSONEncoder().encode(children)   { userDefaults.set(cd, forKey: "children") }
        if let ed = try? JSONEncoder().encode(events)     { userDefaults.set(ed, forKey: "events") }
        if let ud = try? JSONEncoder().encode(currentUser){ userDefaults.set(ud, forKey: "currentUser") }
        if let ld = try? JSONEncoder().encode(linkedMembers){ userDefaults.set(ld, forKey: "linkedMembers") }
        userDefaults.set(householdCode, forKey: "householdCode")
        userDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
    }

    private func loadFromDefaults() {
        if let cd = userDefaults.data(forKey: "children"),
           let c = try? JSONDecoder().decode([Child].self, from: cd)              { children = c }
        if let ed = userDefaults.data(forKey: "events"),
           let e = try? JSONDecoder().decode([SaathEvent].self, from: ed)         { events = e }
        if let ud = userDefaults.data(forKey: "currentUser"),
           let u = try? JSONDecoder().decode(HouseholdMember.self, from: ud)      { currentUser = u }
        if let ld = userDefaults.data(forKey: "linkedMembers"),
           let l = try? JSONDecoder().decode([HouseholdMember].self, from: ld)    { linkedMembers = l }
        householdCode          = userDefaults.string(forKey: "householdCode") ?? generateCode()
        hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
    }

    /// Call this to wipe all data and re-run onboarding (e.g. after sign-out)
    func resetForNewUser() {
        children               = []
        events                 = []
        linkedMembers          = []
        householdCode          = generateCode()
        hasCompletedOnboarding = false
        currentUser            = HouseholdMember(name: "You", role: "Parent")
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }

    private func generateCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let code = String((0..<6).map { _ in letters.randomElement()! })
        return "SAATH-\(code)"
    }

    // MARK: - Children CRUD

    func addChild(name: String, dob: Date, gender: String) {
        let isFirst = children.isEmpty
        let child = Child(name: name, dob: dob, gender: gender, isActive: isFirst)
        children.append(child)
        if isFirst { setActiveChild(id: child.id) }
        save()
    }

    func updateChild(_ updated: Child) {
        guard let i = children.firstIndex(where: { $0.id == updated.id }) else { return }
        children[i] = updated
        save()
    }

    func deleteChild(id: UUID) {
        children.removeAll { $0.id == id }
        events.removeAll  { $0.childId == id }
        // Promote next child as active if needed
        if !children.isEmpty && children.allSatisfy({ !$0.isActive }) {
            children[0].isActive = true
        }
        save()
    }

    func setActiveChild(id: UUID) {
        for i in children.indices { children[i].isActive = (children[i].id == id) }
        save()
    }

    var activeChild: Child? { children.first(where: { $0.isActive }) }

    func childName(for id: UUID?) -> String? {
        guard let id else { return nil }
        return children.first(where: { $0.id == id })?.name
    }

    func child(for id: UUID?) -> Child? {
        guard let id else { return nil }
        return children.first(where: { $0.id == id })
    }

    // MARK: - Events CRUD

    func addEvent(_ e: SaathEvent) {
        events.append(e)
        save()
        Task {
            await CalendarSyncService.shared.upsert(
                event: e,
                childName: childName(for: e.childId)
            )
        }
    }

    func updateEvent(_ updated: SaathEvent) {
        guard let i = events.firstIndex(where: { $0.id == updated.id }) else { return }
        events[i] = updated
        save()
        let snapshot = events[i]
        Task {
            await CalendarSyncService.shared.upsert(
                event: snapshot,
                childName: childName(for: snapshot.childId)
            )
        }
    }

    func deleteEvent(id: UUID) {
        // Capture the Saath UUID before removing — used to find & delete iOS Calendar entry
        let saathId = events.first(where: { $0.id == id })?.id.uuidString
        events.removeAll { $0.id == id }
        save()
        if let saathId {
            Task { await CalendarSyncService.shared.delete(saathId: saathId) }
        }
    }

    func claimEvent(id: UUID) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        events[i].isClaimed = true
        events[i].claimedBy = currentUser.name
        save()
        // Intentionally NOT syncing to iOS Calendar —
        // claim status is Saath-only. Syncing here caused duplicates.
    }

    func unclaimEvent(id: UUID) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        events[i].isClaimed = false
        events[i].claimedBy = nil
        save()
        // Same — no iOS Calendar sync on claim changes.
    }

    // MARK: - Queries

    func eventsForDay(_ day: Date) -> [SaathEvent] {
        events
            .filter { Calendar.current.isDate($0.startTime, inSameDayAs: day) }
            .sorted { $0.startTime < $1.startTime }
    }

    func todayEvents(filter: EventFilter) -> [SaathEvent] {
        let day = eventsForDay(Date())
        switch filter {
        case .all:           return day
        case .family:        return day.filter { $0.childId == nil }
        case .child(let id): return day.filter { $0.childId == id }
        }
    }

    func upcomingEvents(limit: Int = 3) -> [SaathEvent] {
        let now = Date()
        return events
            .filter { $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }
            .prefix(limit)
            .map { $0 }
    }

    func daysWithEvents(year: Int, month: Int) -> Set<Int> {
        var result = Set<Int>()
        for e in events {
            let c = Calendar.current.dateComponents([.year, .month, .day], from: e.startTime)
            if c.year == year && c.month == month { result.insert(c.day ?? 0) }
        }
        return result
    }

    // MARK: - Household

    var allMembers: [HouseholdMember] {
        [currentUser] + linkedMembers
    }

    /// Simulate linking a partner by code.
    /// In production this would be a Firestore/backend call.
    func joinHousehold(code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        // Accept any valid SAATH-XXXXXX format or our own code (demo)
        guard cleaned.hasPrefix("SAATH-"), cleaned.count == 12 else { return false }
        guard !linkedMembers.contains(where: { _ in cleaned == householdCode }) else { return false }

        let partner = HouseholdMember(name: "Partner", role: "Parent")
        linkedMembers.append(partner)
        save()
        return true
    }

    func removeLinkedMember(id: UUID) {
        linkedMembers.removeAll { $0.id == id }
        save()
    }

    func updateCurrentUser(name: String, role: String) {
        currentUser.name = name
        currentUser.role = role
        save()
    }
}

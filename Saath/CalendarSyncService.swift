import EventKit
import Foundation
import Combine
import UIKit

class CalendarSyncService: ObservableObject {

    static let shared = CalendarSyncService()

    private let calTitle = "Saath"
    private let saathTag = "SAATH_ID:"

    @Published var isAuthorized = false
    @Published var lastSyncLog  = ""

    private init() { refreshAuthStatus() }

    // MARK: - Auth

    func refreshAuthStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            // Must be fullAccess — writeOnly cannot read events back for search
            self.isAuthorized = (status == .fullAccess)
        }
    }

    func requestAccess() async -> Bool {
        let store = EKEventStore()
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                // fullAccess required on both device AND simulator
                // writeOnly cannot read events back — search always returns empty
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            DispatchQueue.main.async { self.isAuthorized = granted }
            log(granted ? "✅ Full access granted" : "❌ Access denied")
            return granted
        } catch {
            log("❌ \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Upsert

    @discardableResult
    func upsert(event: SaathEvent, childName: String?) async -> String? {
        guard isAuthorized else {
            log("⚠️ Not authorized — go to Settings → iOS Calendar Sync → Enable")
            return nil
        }

        let store    = EKEventStore()
        guard let cal = saathCalendar(store: store) else { return nil }

        let saathId  = event.id.uuidString
        let tag      = "\(saathTag)\(saathId)"
        let existing = search(tag: tag, store: store)

        let ekEvent  = existing ?? EKEvent(eventStore: store)
        if existing == nil {
            ekEvent.calendar = cal
            log("➕ Creating '\(event.title)'")
        } else {
            log("📝 Updating '\(event.title)'")
        }

        ekEvent.title    = buildTitle(event: event, childName: childName)
        ekEvent.notes    = "\(tag)\n📱 Managed in Saath.\n\(event.notes)"
        ekEvent.location = event.location.isEmpty ? nil : event.location
        ekEvent.isAllDay = event.allDay

        let start         = event.startTime
        ekEvent.startDate = event.allDay
            ? Calendar.current.startOfDay(for: start) : start
        ekEvent.endDate   = event.allDay
            ? Calendar.current.startOfDay(for: start).addingTimeInterval(86400)
            : start.addingTimeInterval(3600)

        do {
            try store.save(ekEvent, span: .thisEvent, commit: true)
            log("✅ Synced '\(event.title)'")
            return ekEvent.eventIdentifier
        } catch {
            log("❌ Save failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Delete

    func delete(saathId: String) async {
        guard isAuthorized else { return }

        let store = EKEventStore()
        let tag   = "\(saathTag)\(saathId)"

        guard let ekEvent = search(tag: tag, store: store) else {
            log("⚠️ Not found for deletion (id: \(saathId.prefix(8)))")
            return
        }
        do {
            try store.remove(ekEvent, span: .thisEvent, commit: true)
            log("🗑 Deleted '\(ekEvent.title ?? "")'")
        } catch {
            log("❌ Delete failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Search all calendars by embedded tag

    private func search(tag: String, store: EKEventStore) -> EKEvent? {
        let start = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let end   = Calendar.current.date(byAdding: .year, value:  2, to: Date())!
        let pred  = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let all   = store.events(matching: pred)
        log("🔍 Searching \(all.count) events for tag")
        return all.first { $0.notes?.contains(tag) == true }
    }

    // MARK: - Find or create Saath calendar

    private func saathCalendar(store: EKEventStore) -> EKCalendar? {
        if let existing = store.calendars(for: .event)
            .first(where: { $0.title == calTitle }) { return existing }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title   = calTitle
        cal.cgColor = UIColor(red: 0.05, green: 0.58, blue: 0.53, alpha: 1).cgColor

        let sorted = store.sources.sorted {
            let order: [EKSourceType] = [.calDAV, .exchange, .local]
            return (order.firstIndex(of: $0.sourceType) ?? 99) <
                   (order.firstIndex(of: $1.sourceType) ?? 99)
        }
        for source in sorted {
            cal.source = source
            if (try? store.saveCalendar(cal, commit: true)) != nil {
                log("✅ Created 'Saath' calendar under '\(source.title)'")
                return cal
            }
        }
        if let def = store.defaultCalendarForNewEvents {
            log("⚠️ Using default calendar '\(def.title)'")
            return def
        }
        log("❌ No usable calendar"); return nil
    }

    // MARK: - Helpers

    private func buildTitle(event: SaathEvent, childName: String?) -> String {
        let base = "\(event.categoryEmoji) \(event.title)"
        return childName.map { "\(base) (\($0))" } ?? base
    }

    private func log(_ message: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("CalendarSync: \(message)")
        DispatchQueue.main.async { self.lastSyncLog = "[\(ts)] \(message)" }
    }
}

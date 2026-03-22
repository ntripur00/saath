import Foundation
import SwiftUI

// MARK: - Child

struct Child: Identifiable, Equatable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var dob: Date
    var gender: String
    var isActive: Bool
    var createdAt: Date = Date()

    var age: String {
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: Date())
        let y = comps.year ?? 0
        let m = max(0, comps.month ?? 0)
        if y == 0 { return "\(m) month\(m == 1 ? "" : "s") old" }
        if y == 1 { return "1 yr, \(m) mo old" }
        return "\(y) yrs, \(m) mo old"
    }

    var initial: String { String(name.prefix(1)).uppercased() }

    var genderIcon: String {
        switch gender {
        case "Male":   return "person.fill"
        case "Female": return "person.fill"
        default:       return "person.fill"
        }
    }

    var avatarColor: Color {
        switch gender {
        case "Male":   return DS.blue
        case "Female": return DS.pink
        default:       return DS.purple
        }
    }
}

// MARK: - Event

struct SaathEvent: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var title: String
    var childId: UUID?
    var startTime: Date
    var category: String
    var notes: String
    var allDay: Bool
    var location: String
    var isClaimed: Bool
    var claimedBy: String?
    var iosEventId: String?          // EKEvent identifier for iOS Calendar sync
    var createdAt: Date = Date()

    var timeString: String {
        if allDay { return "All Day" }
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: startTime)
    }

    var categoryColor: Color {
        switch category.lowercased() {
        case "medical":            return Color(hex: "EF4444")
        case "school":             return Color(hex: "3B82F6")
        case "sports":             return Color(hex: "10B981")
        case "social":             return Color(hex: "EC4899")
        case "grooming (haircut)": return Color(hex: "92400E")
        case "chores/tasks":       return Color(hex: "6B7280")
        case "travel":             return Color(hex: "8B5CF6")
        case "milestones":         return Color(hex: "F59E0B")
        case "extra-curricular":   return Color(hex: "06B6D4")
        case "routine":            return Color(hex: "84CC16")
        default:                   return DS.primary
        }
    }

    var categoryEmoji: String {
        switch category.lowercased() {
        case "medical":            return "🏥"
        case "school":             return "📚"
        case "sports":             return "⚽"
        case "social":             return "🎉"
        case "grooming (haircut)": return "✂️"
        case "chores/tasks":       return "🧹"
        case "travel":             return "✈️"
        case "milestones":         return "🏆"
        case "extra-curricular":   return "🎨"
        case "routine":            return "🌅"
        default:                   return "📅"
        }
    }

    static let categories = [
        "General", "Medical", "School", "Sports", "Social",
        "Grooming (Haircut)", "Extra-Curricular", "Chores/Tasks",
        "Routine", "Travel", "Milestones", "Other"
    ]
}

// MARK: - Household Member

struct HouseholdMember: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var name: String
    var role: String   // "Parent", "Guardian", etc.
    var joinedAt: Date = Date()

    var initial: String { String(name.prefix(1)).uppercased() }
}

// MARK: - Event Filter

enum EventFilter: Equatable {
    case all, family, child(UUID)

    var label: String {
        switch self {
        case .all:         return "All"
        case .family:      return "Family"
        case .child:       return ""
        }
    }
}

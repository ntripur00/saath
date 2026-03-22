import SwiftUI

// MARK: - Children List

struct ChildrenView: View {
    @EnvironmentObject var store: DataStore
    @State private var editingChild: Child? = nil
    @State private var showAddChild         = false
    @State private var deleteTarget: Child? = nil
    @State private var showDeleteAlert      = false

    var body: some View {
        Group {
            if store.children.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No children added yet",
                    subtitle: "Add your first child profile to start\ntracking events and milestones.",
                    action: { showAddChild = true },
                    actionLabel: "Add Child Profile"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: DS.sm) {

                        // Active child banner
                        if let active = store.activeChild {
                            ActiveChildBanner(child: active)
                                .padding(.horizontal, DS.md)
                                .padding(.top, DS.md)
                        }

                        SectionLabel(text: "All Profiles")
                            .padding(.horizontal, DS.md)
                            .padding(.top, DS.md)

                        ForEach(store.children) { child in
                            ChildCard(child: child,
                                      eventsCount: store.events.filter { $0.childId == child.id }.count)
                            {
                                store.setActiveChild(id: child.id)
                            } onEdit: {
                                editingChild = child
                            } onDelete: {
                                deleteTarget  = child
                                showDeleteAlert = true
                            }
                            .padding(.horizontal, DS.md)
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .background(DS.background)
        .navigationTitle("Children")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddChild = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(DS.primary)
                }
            }
        }
        // Add sheet
        .sheet(isPresented: $showAddChild) {
            NavigationStack { AddChildView() }
        }
        // Edit sheet
        .sheet(item: $editingChild) { child in
            NavigationStack { AddChildView(editChild: child) }
        }
        // Delete alert
        .alert(
            "Delete \(deleteTarget?.name ?? "Child")?",
            isPresented: $showDeleteAlert,
            presenting: deleteTarget
        ) { child in
            Button("Delete", role: .destructive) {
                withAnimation { store.deleteChild(id: child.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { child in
            Text("This will remove \(child.name) and all their associated events. This cannot be undone.")
        }
    }
}

// MARK: - Active Child Banner

struct ActiveChildBanner: View {
    let child: Child

    var body: some View {
        HStack(spacing: DS.md) {
            AvatarView(initial: child.initial, color: child.avatarColor, size: 50, isActive: true)

            VStack(alignment: .leading, spacing: 2) {
                Text(child.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Text(child.age)
                    .font(.system(size: 13))
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            PillBadge(text: "Active", color: DS.primary)
        }
        .padding(DS.md)
        .background(
            LinearGradient(
                colors: [DS.primary.opacity(0.08), DS.primary.opacity(0.03)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusXl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusXl, style: .continuous)
                .stroke(DS.primary.opacity(0.25), lineWidth: 2)
        )
    }
}

// MARK: - Child Card

struct ChildCard: View {
    let child: Child
    let eventsCount: Int
    let onSelect: () -> Void
    let onEdit:   () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DS.md) {
            Button(action: onSelect) {
                HStack(spacing: DS.md) {
                    AvatarView(
                        initial: child.initial,
                        color: child.avatarColor,
                        size: 52,
                        isActive: child.isActive
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(child.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                            if child.isActive {
                                PillBadge(text: "Active", color: DS.primary, small: true)
                            }
                        }

                        HStack(spacing: DS.sm) {
                            Text(child.age)
                                .font(.system(size: 13))
                                .foregroundColor(DS.textSecondary)

                            Text("•")
                                .foregroundColor(DS.textTertiary)

                            Text(child.gender)
                                .font(.system(size: 13))
                                .foregroundColor(DS.textSecondary)
                        }

                        if eventsCount > 0 {
                            Text("\(eventsCount) event\(eventsCount == 1 ? "" : "s")")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(DS.textTertiary)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Action buttons
            VStack(spacing: DS.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.primary)
                        .frame(width: 32, height: 32)
                        .background(DS.primaryLight)
                        .clipShape(Circle())
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.danger)
                        .frame(width: 32, height: 32)
                        .background(DS.danger.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(DS.md)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusLg, style: .continuous)
                .stroke(child.isActive ? child.avatarColor.opacity(0.3) : DS.border,
                        lineWidth: child.isActive ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Add / Edit Child View

struct AddChildView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var editChild: Child? = nil

    @State private var name   = ""
    @State private var dob    = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
    @State private var gender = "Female"

    private let genders = ["Female", "Male", "Other"]
    private var isEditing: Bool { editChild != nil }
    private var canSave: Bool   { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    init(editChild: Child? = nil) {
        self.editChild = editChild
        if let c = editChild {
            _name   = State(initialValue: c.name)
            _dob    = State(initialValue: c.dob)
            _gender = State(initialValue: c.gender)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.lg) {

                // Avatar preview
                VStack(spacing: DS.sm) {
                    AvatarView(
                        initial: name.isEmpty ? "?" : String(name.prefix(1)).uppercased(),
                        color: genderColor,
                        size: 80
                    )
                    if !name.isEmpty {
                        Text(name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(DS.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, DS.md)

                // Form fields
                VStack(spacing: DS.lg) {
                    // Name
                    SaathInputField(
                        label: "Child's Name",
                        icon: "person.fill",
                        text: $name,
                        placeholder: "e.g. Advait"
                    )

                    // DOB
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Date of Birth")
                        DatePicker("", selection: $dob,
                                   in: ...Date(),
                                   displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(DS.primary)
                            .padding(.horizontal, DS.md)
                            .padding(.vertical, 13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DS.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                    .stroke(DS.border, lineWidth: 1)
                            )

                        if !name.isEmpty {
                            Text(calculatedAge)
                                .font(.system(size: 12))
                                .foregroundColor(DS.textSecondary)
                                .padding(.horizontal, 4)
                        }
                    }

                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Gender")
                        HStack(spacing: DS.sm) {
                            ForEach(genders, id: \.self) { g in
                                GenderButton(label: g,
                                             selected: gender == g,
                                             color: colorFor(g)) {
                                    gender = g
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.md)

                // Save button
                Button(action: save) {
                    Text(isEditing ? "Update Profile" : "Save Profile")
                        .primaryButton(disabled: !canSave)
                }
                .disabled(!canSave)
                .padding(.horizontal, DS.md)
                .padding(.bottom, DS.lg)
            }
        }
        .background(DS.background)
        .navigationTitle(isEditing ? "Edit Child" : "Add Child")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.foregroundColor(DS.primary)
            }
        }
    }

    private var genderColor: Color { colorFor(gender) }

    private func colorFor(_ g: String) -> Color {
        switch g {
        case "Male":   return DS.blue
        case "Female": return DS.pink
        default:       return DS.purple
        }
    }

    private var calculatedAge: String {
        let comps = Calendar.current.dateComponents([.year, .month], from: dob, to: Date())
        let y = comps.year ?? 0
        let m = max(0, comps.month ?? 0)
        if y == 0 { return "\(m) month\(m == 1 ? "" : "s") old" }
        return "\(y) year\(y == 1 ? "" : "s"), \(m) month\(m == 1 ? "" : "s") old"
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if var child = editChild {
            child.name   = trimmed
            child.dob    = dob
            child.gender = gender
            store.updateChild(child)
        } else {
            store.addChild(name: trimmed, dob: dob, gender: gender)
        }
        dismiss()
    }
}

// MARK: - Gender Button

struct GenderButton: View {
    let label:    String
    let selected: Bool
    let color:    Color
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: selected ? "circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(selected ? color : DS.textTertiary)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selected ? color : DS.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? color.opacity(0.12) : DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(selected ? color.opacity(0.4) : DS.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
    }
}

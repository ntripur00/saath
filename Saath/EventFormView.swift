import SwiftUI

struct EventFormView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var event: SaathEvent? = nil

    @State private var title    = ""
    @State private var category = "General"
    @State private var childId: UUID? = nil
    @State private var startTime    = Date()
    @State private var allDay       = false
    @State private var location     = ""
    @State private var notes        = ""
    @State private var showDeleteAlert = false

    private var isEditing: Bool { event != nil }
    private var canSave:   Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    init(event: SaathEvent? = nil) {
        self.event = event
        if let e = event {
            _title     = State(initialValue: e.title)
            _category  = State(initialValue: e.category)
            _childId   = State(initialValue: e.childId)
            _startTime = State(initialValue: e.startTime)
            _allDay    = State(initialValue: e.allDay)
            _location  = State(initialValue: e.location)
            _notes     = State(initialValue: e.notes)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Category colour header ──
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [previewColor.opacity(0.15), previewColor.opacity(0.03)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 90)

                    HStack(spacing: DS.md) {
                        Text(previewEmoji)
                            .font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(previewColor)
                            Text(title.isEmpty ? "New Event" : title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(DS.textPrimary)
                                .lineLimit(1)
                        }
                    }
                    .padding(DS.md)
                }

                // ── Fields ──
                VStack(spacing: DS.lg) {

                    // Title
                    SaathInputField(
                        label: "Event Title",
                        icon: "pencil",
                        text: $title,
                        placeholder: "e.g. Doctor Visit"
                    )

                    // Category
                    formField(label: "Category") {
                        Menu {
                            ForEach(SaathEvent.categories, id: \.self) { cat in
                                Button {
                                    withAnimation { category = cat }
                                } label: {
                                    Label(cat, systemImage: "circle.fill")
                                }
                            }
                        } label: {
                            HStack {
                                Text(previewEmoji).font(.system(size: 18))
                                Text(category)
                                    .font(.system(size: 15))
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 13))
                                    .foregroundColor(DS.textTertiary)
                            }
                            .padding(.horizontal, DS.md)
                            .padding(.vertical, 13)
                            .background(DS.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                    .stroke(DS.border, lineWidth: 1)
                            )
                        }
                    }

                    // Who is this for
                    formField(label: "Who Is This For?") {
                        Menu {
                            Button {
                                childId = nil
                            } label: {
                                Label("Family / General", systemImage: "house.fill")
                            }
                            ForEach(store.children) { child in
                                Button { childId = child.id } label: {
                                    Label(child.name, systemImage: "person.fill")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: childId == nil ? "house.fill" : "person.fill")
                                    .foregroundColor(DS.textTertiary)
                                    .frame(width: 20)
                                Text(store.childName(for: childId) ?? "Family / General")
                                    .font(.system(size: 15))
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 13))
                                    .foregroundColor(DS.textTertiary)
                            }
                            .padding(.horizontal, DS.md)
                            .padding(.vertical, 13)
                            .background(DS.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                    .stroke(DS.border, lineWidth: 1)
                            )
                        }
                    }

                    // All day toggle
                    HStack {
                        Label("All Day Event", systemImage: "sun.max.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.textPrimary)
                        Spacer()
                        Toggle("", isOn: $allDay)
                            .tint(DS.primary)
                            .labelsHidden()
                    }
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, 13)
                    .background(DS.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                            .stroke(DS.border, lineWidth: 1)
                    )

                    // Date & Time
                    formField(label: "Date & Time") {
                        DatePicker("",
                                   selection: $startTime,
                                   displayedComponents: allDay ? .date : [.date, .hourAndMinute])
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
                    }

                    // Location
                    SaathInputField(
                        label: "Location (optional)",
                        icon: "location.fill",
                        text: $location,
                        placeholder: "e.g. City Hospital"
                    )

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Notes (optional)")
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(minHeight: 90)
                                .padding(8)
                                .font(.system(size: 15))
                                .scrollContentBackground(.hidden)
                                .background(DS.surface)
                            if notes.isEmpty {
                                Text("Add notes, reminders, what to bring…")
                                    .font(.system(size: 15))
                                    .foregroundColor(DS.textTertiary)
                                    .padding(.top, 16)
                                    .padding(.leading, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(DS.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                                .stroke(DS.border, lineWidth: 1)
                        )
                    }

                    // Save button
                    Button(action: save) {
                        Text(isEditing ? "Update Event" : "Save Event")
                            .primaryButton(disabled: !canSave)
                    }
                    .disabled(!canSave)

                    // Delete button (edit mode only)
                    if isEditing {
                        Button { showDeleteAlert = true } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(DS.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(DS.danger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding(DS.md)
            }
        }
        .background(DS.background)
        .navigationTitle(isEditing ? "Edit Event" : "New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.foregroundColor(DS.primary)
            }
        }
        .confirmationDialog(
            "Delete \"\(event?.title ?? "Event")\"?",
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete Event", role: .destructive) {
                if let e = event {
                    store.deleteEvent(id: e.id)   // DataStore deletes from iOS Calendar too
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Helpers

    private var previewColor: Color {
        let dummy = makeDummyEvent()
        return dummy.categoryColor
    }

    private var previewEmoji: String {
        let dummy = makeDummyEvent()
        return dummy.categoryEmoji
    }

    private func makeDummyEvent() -> SaathEvent {
        SaathEvent(
            title:     "",
            childId:   nil,
            startTime: Date(),
            category:  category,
            notes:     "",
            allDay:    false,
            location:  "",
            isClaimed: false
        )
    }

    @ViewBuilder
    private func formField<Content: View>(label: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: label)
            content()
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if var e = event {
            e.title     = trimmed
            e.category  = category
            e.childId   = childId
            e.startTime = startTime
            e.allDay    = allDay
            e.location  = location
            e.notes     = notes
            store.updateEvent(e)   // DataStore preserves iosEventId and syncs
        } else {
            let newEvent = SaathEvent(
                title:     trimmed,
                childId:   childId,
                startTime: startTime,
                category:  category,
                notes:     notes,
                allDay:    allDay,
                location:  location,
                isClaimed: false
            )
            store.addEvent(newEvent)   // DataStore syncs and stores iosEventId
        }
        dismiss()
    }
}

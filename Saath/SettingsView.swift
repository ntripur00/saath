import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var auth:  AuthService
    @State private var showEditProfile  = false
    @State private var showJoinSheet    = false
    @State private var codeCopied       = false
    @State private var joinCode         = ""
    @State private var joinError        = false
    @State private var joinSuccess      = false
    @State private var showLogoutAlert  = false
    @State private var removeMemberId: UUID? = nil
    @State private var showRemoveAlert  = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Profile Header ──
                profileHeader
                    .padding(.horizontal, DS.md)
                    .padding(.top, DS.md)

                // ── Household Section ──
                sectionBlock("Household & Sharing") {
                    VStack(spacing: DS.sm) {
                        householdCodeCard
                        joinCard
                        if !store.linkedMembers.isEmpty {
                            linkedMembersCard
                        }
                    }
                }

                // ── Notifications ──
                sectionBlock("App Settings") {
                    VStack(spacing: 0) {
                        // iOS Calendar Sync
                        calendarSyncRow
                        SDivider().padding(.leading, 52)
                        settingsRow(icon: "bell.fill",         color: DS.danger,   title: "Notifications",    subtitle: "Manage alerts")
                        SDivider().padding(.leading, 52)
                        settingsRow(icon: "icloud.fill",       color: DS.blue,     title: "Backup & Sync",    subtitle: "iCloud sync")
                        SDivider().padding(.leading, 52)
                        settingsRow(icon: "lock.fill",         color: DS.primary,  title: "Privacy",          subtitle: "Data & permissions")
                        SDivider().padding(.leading, 52)
                        settingsRow(icon: "questionmark.circle.fill", color: DS.warning, title: "Help & Support", subtitle: "FAQs, contact us")
                    }
                    .surfaceCard(padding: 0)
                }

                // ── About ──
                sectionBlock("About") {
                    VStack(spacing: 0) {
                        aboutRow(title: "Version", value: "1.0.0")
                        SDivider().padding(.leading, DS.md)
                        aboutRow(title: "Built with", value: "SwiftUI & ❤️")
                    }
                    .surfaceCard(padding: 0)
                }

                // ── Logout ──
                Button { showLogoutAlert = true } label: {
                    HStack {
                        Image(systemName: "arrow.backward.circle.fill")
                        Text("Log Out")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                }
                .padding(.horizontal, DS.md)
                .padding(.top, DS.sm)

                Spacer(minLength: 120)
            }
        }
        .background(DS.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) { EditProfileSheet() }
        .alert("Log Out?", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                store.resetForNewUser()
                auth.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Remove member?", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) {
                if let id = removeMemberId { store.removeLinkedMember(id: id) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(toastOverlay)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: DS.md) {
            // Use Firebase photo if available, else initials
            if let url = auth.currentUser?.photoURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(DS.primaryLight)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(DS.border, lineWidth: 1))
            } else {
                AvatarView(
                    initial: auth.currentUser?.initials ?? store.currentUser.initial,
                    color: DS.primary,
                    size: 60
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(auth.currentUser?.displayName ?? store.currentUser.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Text(auth.currentUser?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(DS.textSecondary)
                PillBadge(text: store.currentUser.role, color: DS.primary, small: true)
            }
            Spacer()
            Button { showEditProfile = true } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DS.primary)
            }
        }
        .padding(DS.md)
        .surfaceCard(radius: DS.radiusXl)
    }

    // MARK: - Household Code Card

    private var householdCodeCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            HStack {
                Label("Your Household Code", systemImage: "house.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                PillBadge(text: "\(store.allMembers.count) member\(store.allMembers.count == 1 ? "" : "s")",
                          color: DS.primary, small: true)
            }

            Text("Share this code with your partner or co-parent so they can join your household and see all events.")
                .font(.system(size: 13))
                .foregroundColor(DS.textSecondary)
                .lineSpacing(2)

            // Code display
            HStack {
                Text(store.householdCode)
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundColor(DS.primary)
                    .kerning(1)
                Spacer()
                Button {
                    UIPasteboard.general.string = store.householdCode
                    withAnimation { codeCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { codeCopied = false }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                        Text(codeCopied ? "Copied!" : "Copy")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(codeCopied ? DS.success : DS.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(codeCopied ? DS.success.opacity(0.1) : DS.primaryLight)
                    .clipShape(Capsule())
                }
                .animation(.spring(response: 0.3), value: codeCopied)
            }
            .padding(DS.md)
            .background(DS.background)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.primary.opacity(0.2), lineWidth: 1.5)
            )
        }
        .padding(DS.md)
        .surfaceCard(padding: 0)
    }

    // MARK: - Join Card

    private var joinCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            Label("Join a Household", systemImage: "person.badge.plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.textPrimary)

            Text("Enter your partner's household code to link your accounts and share events in real time.")
                .font(.system(size: 13))
                .foregroundColor(DS.textSecondary)
                .lineSpacing(2)

            HStack(spacing: DS.sm) {
                TextField("e.g. SAATH-ABC123", text: $joinCode)
                    .font(.system(size: 15, design: .monospaced))
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, 12)
                    .background(DS.background)
                    .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                            .stroke(joinError ? DS.danger : DS.border, lineWidth: 1)
                    )

                Button { attemptJoin() } label: {
                    Text("Link")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, DS.md)
                        .padding(.vertical, 12)
                        .background(joinCode.isEmpty ? DS.primary.opacity(0.4) : DS.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
                }
                .disabled(joinCode.isEmpty)
            }

            if joinError {
                Label("Invalid code. Must be in format SAATH-XXXXXX", systemImage: "exclamationmark.circle")
                    .font(.system(size: 12))
                    .foregroundColor(DS.danger)
            }
            if joinSuccess {
                Label("Partner linked successfully!", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DS.success)
            }
        }
        .padding(DS.md)
        .surfaceCard(padding: 0)
    }

    // MARK: - Linked Members

    private var linkedMembersCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            Label("Household Members", systemImage: "person.2.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.textPrimary)

            // Current user (you)
            memberRow(
                name: store.currentUser.name,
                role: store.currentUser.role,
                initial: store.currentUser.initial,
                isYou: true,
                onRemove: nil
            )

            ForEach(store.linkedMembers) { member in
                SDivider()
                memberRow(
                    name: member.name,
                    role: member.role,
                    initial: member.initial,
                    isYou: false
                ) {
                    removeMemberId = member.id
                    showRemoveAlert = true
                }
            }
        }
        .padding(DS.md)
        .surfaceCard(padding: 0)
    }

    private func memberRow(name: String, role: String, initial: String,
                           isYou: Bool, onRemove: (() -> Void)?) -> some View {
        HStack(spacing: DS.md) {
            AvatarView(initial: initial, color: isYou ? DS.primary : DS.secondary, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DS.sm) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DS.textPrimary)
                    if isYou {
                        PillBadge(text: "You", color: DS.primary, small: true)
                    }
                }
                Text(role)
                    .font(.system(size: 12))
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DS.textTertiary)
                }
            }
        }
    }

    // MARK: - Calendar Sync Row

    @ObservedObject private var syncService = CalendarSyncService.shared

    private var calendarSyncRow: some View {
        HStack(spacing: DS.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "34C759"))
                    .frame(width: 32, height: 32)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("iOS Calendar Sync")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DS.textPrimary)
                Text(syncService.isAuthorized
                     ? "Events sync to your Apple Calendar"
                     : "Tap to enable — shows Saath events in Apple Calendar")
                    .font(.system(size: 12))
                    .foregroundColor(syncService.isAuthorized ? DS.success : DS.textSecondary)
            }
            Spacer()
            if syncService.isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DS.success)
            } else {
                Text("Enable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.primaryLight)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if !syncService.isAuthorized {
                Task { await syncService.requestAccess() }
            }
        }
    }

    // MARK: - Helpers

    private func sectionBlock<Content: View>(_ title: String,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            SectionLabel(text: title)
                .padding(.horizontal, DS.md)
                .padding(.top, DS.lg)
                .padding(.bottom, DS.xs)
            content()
                .padding(.horizontal, DS.md)
        }
    }

    private func settingsRow(icon: String, color: Color,
                              title: String, subtitle: String) -> some View {
        Button(action: {}) {
            HStack(spacing: DS.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(DS.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(DS.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textTertiary)
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(DS.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(DS.textSecondary)
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, 14)
    }

    private func attemptJoin() {
        let success = store.joinHousehold(code: joinCode)
        withAnimation {
            joinError   = !success
            joinSuccess = success
        }
        if success {
            joinCode = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { joinSuccess = false }
            }
        }
    }

    private var toastOverlay: some View {
        VStack {
            Spacer()
            if codeCopied {
                Text("✓  Household code copied!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, DS.lg)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .shadow(radius: 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 110)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: codeCopied)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var role = ""
    private let roles = ["Parent", "Guardian", "Grandparent", "Other"]

    init() {
        // Will be set in onAppear
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.lg) {
                    AvatarView(
                        initial: name.isEmpty ? "?" : String(name.prefix(1)).uppercased(),
                        color: DS.primary,
                        size: 80
                    )
                    .padding(.top, DS.md)

                    SaathInputField(
                        label: "Your Name",
                        icon: "person.fill",
                        text: $name,
                        placeholder: "e.g. Anil Sharma"
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Your Role")
                        Picker("Role", selection: $role) {
                            ForEach(roles, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .tint(DS.primary)
                    }

                    Button {
                        store.updateCurrentUser(name: name, role: role)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .primaryButton(disabled: name.isEmpty)
                    }
                    .disabled(name.isEmpty)
                }
                .padding(DS.md)
            }
            .background(DS.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(DS.primary)
                }
            }
            .onAppear {
                name = store.currentUser.name
                role = store.currentUser.role
            }
        }
    }
}

import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable var appState: AppState

    @State private var apiKeyInput: String = ""
    @State private var tokenInput: String = ""
    @State private var testStatus: String?
    @State private var isTesting: Bool = false
    @State private var isSuccess: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Settings Header
            HStack {
                Text("Settings & Customization")
                    .font(.system(size: 13, weight: .bold))

                Spacer()

                Button("Done") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.showingSettings = false
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. Trello API Credentials
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Trello Credentials")
                            .font(.system(size: 12, weight: .bold))

                        Text("Generate your free API Key and Personal Token from Trello:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Button(action: {
                            if let url = URL(string: "https://trello.com/app-key") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "safari")
                                Text("Open trello.com/app-key")
                            }
                            .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.link)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key:")
                                .font(.system(size: 11, weight: .medium))
                            TextField("Enter 32-character API key", text: $apiKeyInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Personal Token:")
                                .font(.system(size: 11, weight: .medium))
                            SecureField("Enter token", text: $tokenInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }

                        HStack {
                            Button("Save & Connect") {
                                saveAndTest()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      isTesting)

                            if isTesting {
                                ProgressView()
                                    .controlSize(.small)
                            }

                            if let status = testStatus {
                                HStack(spacing: 4) {
                                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isSuccess ? .green : .red)
                                    Text(status)
                                        .font(.system(size: 11))
                                        .foregroundColor(isSuccess ? .primary : .red)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // 2. Custom Card Tracking Rules
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Card Tracking Preferences")
                            .font(.system(size: 12, weight: .bold))

                        // Badge Display Mode
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Menu Bar Icon Badge:")
                                .font(.system(size: 11, weight: .medium))

                            Picker("", selection: Bindable(appState.settings).badgeDisplayMode) {
                                ForEach(BadgeDisplayMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Auto-refresh Interval
                        HStack {
                            Text("Auto-Refresh Interval:")
                                .font(.system(size: 11, weight: .medium))

                            Spacer()

                            Picker("", selection: Bindable(appState.settings).refreshIntervalMinutes) {
                                Text("1 minute").tag(1)
                                Text("5 minutes").tag(5)
                                Text("15 minutes").tag(15)
                                Text("30 minutes").tag(30)
                            }
                            .frame(width: 120)
                            .onChange(of: appState.settings.refreshIntervalMinutes) {
                                appState.setupTimer()
                            }
                        }

                        // Hide Completed Toggle
                        Toggle("Hide completed cards automatically", isOn: Bindable(appState.settings).hideCompletedCards)
                            .font(.system(size: 11))
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // 3. Board Selection Filter
                    if !appState.boards.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("3. Boards to Track")
                                    .font(.system(size: 12, weight: .bold))

                                Spacer()

                                if !appState.settings.selectedBoardIDs.isEmpty {
                                    Button("Clear Filter (All)") {
                                        appState.settings.selectedBoardIDs.removeAll()
                                    }
                                    .font(.system(size: 10))
                                    .buttonStyle(.link)
                                }
                            }

                            Text("Select specific boards to track (leave all unchecked to track cards from all boards):")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            ForEach(appState.boards) { board in
                                let isSelected = appState.settings.selectedBoardIDs.contains(board.id)
                                Toggle(isOn: Binding(
                                    get: { isSelected },
                                    set: { _ in appState.settings.toggleBoardSelection(for: board.id) }
                                )) {
                                    Text(board.name)
                                        .font(.system(size: 11))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // 4. App Info & Quit
                    HStack {
                        Spacer()
                        Button("Quit App") {
                            NSApplication.shared.terminate(nil)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(14)
            }
        }
        .onAppear {
            apiKeyInput = appState.settings.apiKey
            tokenInput = appState.settings.token
        }
    }

    private func saveAndTest() {
        let cleanKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanToken = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)

        appState.settings.apiKey = cleanKey
        appState.settings.token = cleanToken

        isTesting = true
        testStatus = nil
        isSuccess = false

        Task {
            let service = TrelloAPIService()
            do {
                let user = try await service.verifyCredentials(apiKey: cleanKey, token: cleanToken)
                await MainActor.run {
                    isTesting = false
                    isSuccess = true
                    testStatus = "Connected as @\(user.username)"
                    Task {
                        await appState.refresh()
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    isSuccess = false
                    testStatus = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

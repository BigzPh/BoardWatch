import SwiftUI
import AppKit

struct MinimalSettingsView: View {
    @Bindable var appState: AppState

    @State private var apiKeyInput: String = ""
    @State private var tokenInput: String = ""
    @State private var testStatus: String?
    @State private var isTesting: Bool = false
    @State private var isSuccess: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "checklist")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
                VStack(alignment: .leading) {
                    Text("BoardWatch Settings")
                        .font(.headline)
                    Text("Track pending cards in your menu bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Credentials section
            VStack(alignment: .leading, spacing: 8) {
                Text("Trello Credentials")
                    .font(.subheadline.bold())

                Button(action: {
                    if let url = URL(string: "https://trello.com/app-key") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                        Text("Get API Key & Token (trello.com/app-key)")
                    }
                    .font(.caption)
                }
                .buttonStyle(.link)

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key:")
                        .font(.caption)
                    TextField("Enter API key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Token:")
                        .font(.caption)
                    SecureField("Enter Token", text: $tokenInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                }

                HStack {
                    Button("Save & Connect") {
                        saveAndConnect()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              isTesting)

                    if isTesting {
                        ProgressView().controlSize(.small)
                    }

                    if let status = testStatus {
                        HStack(spacing: 4) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isSuccess ? .green : .red)
                            Text(status)
                                .font(.caption)
                                .foregroundColor(isSuccess ? .primary : .red)
                        }
                    }
                }
                .padding(.top, 2)
            }

            Divider()

            // Preferences
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferences")
                    .font(.subheadline.bold())

                HStack {
                    Text("Auto-Check Interval:")
                        .font(.caption)
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
            }

            Spacer()

            // Footer
            HStack {
                Button("Quit BoardWatch") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Done") {
                    SettingsWindowController.shared.closeSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 380, height: 420)
        .onAppear {
            apiKeyInput = appState.settings.apiKey
            tokenInput = appState.settings.token
        }
    }

    private func saveAndConnect() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)

        appState.settings.apiKey = key
        appState.settings.token = token

        isTesting = true
        testStatus = nil
        isSuccess = false

        Task {
            let service = TrelloAPIService()
            do {
                let user = try await service.verifyCredentials(apiKey: key, token: token)
                await MainActor.run {
                    isTesting = false
                    isSuccess = true
                    testStatus = "Connected (@\(user.username))"
                    Task {
                        await appState.refresh()
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    isSuccess = false
                    testStatus = "Connection error"
                }
            }
        }
    }
}

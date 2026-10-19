# BoardWatch for Trello

A native, lightweight macOS Menu Bar app built in SwiftUI that tracks pending Trello cards with a glanceable count, native dropdown access, and system notifications.

---

## Features

* **Menu Bar Agent:** Configured with `LSUIElement` to run strictly in the menu bar without appearing in the Dock.
* **Glanceable Status:** Displays an icon and the number of pending tasks directly in the top menu bar.
* **Native Menu Dropdown:** Clicking the menu bar item opens a standard native macOS menu listing cards with due dates and board names. Clicking any card opens it in your browser.
* **Desktop Notifications:** Sends macOS notifications when new cards are assigned or when tasks are due.
* **Configurable Polling:** Automatic background refresh interval (1m, 5m, 15m, 30m) or manual check.

---

## Getting Started

### 1. Launch the Application
```bash
open BoardWatch.app
```

### 2. Connect Your Trello Account
1. Open **Settings...** from the menu bar dropdown.
2. Open the link to [trello.com/app-key](https://trello.com/app-key).
3. Copy your **API Key** and generate a **Personal Token**.
4. Paste both into the settings dialog and click **Save & Connect**.

---

## Building from Source

* **Compile and Package:**
  ```bash
  ./scripts/build_app.sh
  ```
* **Build and Run:**
  ```bash
  ./scripts/build_app.sh --run
  ```
* **Open in Xcode:**
  ```bash
  xed .
  ```

# BoardWatch for Trello 📋

A native, lightweight macOS Menu Bar app built in SwiftUI that lets you monitor, track, and customize what Trello cards you watch directly from your Mac's top menu bar.

---

## Features

* **Lives in your macOS Menu Bar:** Configured with `LSUIElement` so it runs quietly in the top menu bar without cluttering your Dock.
* **Custom Card Tracking (Pin 📌):** 
  * Pin specific cards from any board or list to keep them tracked in your personal **Tracked** view.
  * Filter cards across 3 views: **Tracked** (pinned cards), **Assigned** (assigned to you), and **All**.
* **Board & Project Filtering:** Select specific Trello boards to monitor in **Settings** (or leave unselected to monitor all boards).
* **Live Menu Bar Badge:**
  * Customize what the menu bar counter displays: **Tracked Cards Count**, **All Assigned Incomplete**, **Due Soon / Overdue**, or **Icon Only**.
* **Due Date & Checklist Indicators:**
  * Color-coded due dates (Red for Overdue, Orange for Due Today, Yellow for Tomorrow).
  * Checklist progress (e.g., `☑ 3/5`).
  * Colored label dots matching your Trello board labels.
* **Quick Actions:**
  * Check/uncheck to toggle card completion status directly in Trello via the API.
  * One-click button to open any card directly in your browser.
  * Search bar to instantly filter cards by name, label, or board.
* **Auto-Refresh:** Configurable background refresh timer (1m, 5m, 15m, 30m) or instant manual refresh.

---

## Quick Start

### 1. Launch the App
The app has already been compiled and packaged:
```bash
open BoardWatch.app
```

### 2. Connect Your Trello Account
When you first open the app, it will display the **Settings** panel:
1. Click the link to **[trello.com/app-key](https://trello.com/app-key)**.
2. Copy your **API Key**.
3. Under the *Token* section on the same page, click **Token** to generate an authorized token and copy it.
4. Paste both into the app and click **Save & Connect**.

---

## Customizing What Cards to Track

### Method 1: Pinning Specific Cards (📌)
* In the **Assigned** or **All** tab, hover over any card and click the **📌 pin icon**.
* The card will now always appear under your **Tracked** tab.
* In Settings, set your Menu Bar Badge to **Tracked Cards Count** so the menu bar icon only shows the count of your hand-picked cards!

### Method 2: Filtering by Board
* Open **Settings** (gear icon in the top right).
* Under **Boards to Track**, check only the projects or boards you care about. All other boards will be filtered out.

---

## Development & Rebuilding

* **Rebuild & Package:**
  ```bash
  ./scripts/build_app.sh
  ```
* **Rebuild & Launch Immediately:**
  ```bash
  ./scripts/build_app.sh --run
  ```
* **Open in Xcode:**
  ```bash
  xed .
  ```

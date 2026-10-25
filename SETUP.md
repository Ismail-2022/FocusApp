# Setup — Task 0 Spike (Path B)

> **The project is generated, not committed.** `project.yml` (XcodeGen) defines all
> three targets, so there is no `.xcodeproj` in git. Run `make setup`.

## Fast path

```bash
make doctor   # what's missing from your toolchain
make setup    # install XcodeGen + generate FocusApp.xcodeproj
make demo     # run Demo Mode in the simulator — no account, no entitlement
make open     # open in Xcode for real-device work
```

Demo Mode is the one to use until the £79 membership question is settled. It
exercises every code path except the actual Screen Time calls.

## Real-device path (the capability gate)

1. `cp Local.xcconfig.example Local.xcconfig` and set `DEVELOPMENT_TEAM`
2. `make open`
3. On both the **FocusApp** and **FocusMonitor** targets: Signing & Capabilities →
   confirm **Family Controls** is present (it's declared in `project.yml`, but
   signing is what proves your team is allowed to use it)
4. Build to a real iPhone

**If step 3 or 4 fails on signing, that is the spike's answer.** Copy the exact
error into the findings log. A free personal team is not expected to pass this.

## If XcodeGen's watch embedding misbehaves

The watch-app embedding in `project.yml` is the one part most likely to need a
tweak on a newer Xcode. If `make setup` produces a project where the watch app
isn't embedded, fall back to creating the targets by hand in Xcode (below) and
fix `project.yml` afterwards — don't abandon the generated-project setup, since
it's what makes the repo clonable.

---

## Manual target creation (fallback only)

## 1. Create the project
- Xcode → New Project → **iOS → App**
- Product name: `FocusApp`
- Interface: **SwiftUI**, Language: **Swift**
- Bundle ID: `com.ismail.focusapp` (keep it consistent — the extension derives from it)

## 2. Add the watchOS target
- File → New → Target → **watchOS → App**
- Name: `FocusAppWatch`
- Check **"Watch App for Existing iOS App"** so it pairs to the iOS app

## 3. Add the monitor extension target
- File → New → Target → **iOS → Device Activity Monitor Extension**
- Name: `FocusMonitor`
- Embed in the `FocusApp` iOS target
- In `FocusMonitor/Info.plist`, set `NSExtensionPrincipalClass` to
  `$(PRODUCT_MODULE_NAME).FocusMonitorExtension`

## 4. Capabilities (THE GATE)
On both the **iOS app** and **FocusMonitor** targets:
- Signing & Capabilities → `+ Capability` → **Family Controls**

If the capability is missing or errors on signing, stop. Copy the exact error
into the findings log in the vault note. That is a valid spike result.

## 5. Add the source files
Drag these in, assigning each to the right target:

| Folder | Target(s) |
|---|---|
| `Shared/` | iOS app, FocusMonitor **and** FocusAppWatch (no Screen Time imports — safe on watchOS) |
| `SharedIOS/` | iOS app **and** FocusMonitor only (DeviceActivity/ManagedSettings don't exist on watchOS) |
| `FocusAppiOS/` | iOS app |
| `FocusMonitor/` | FocusMonitor extension |
| `FocusAppWatch/` | FocusAppWatch |

`FocusAppApp.swift` and `WatchApp.swift` both declare `@main` — delete the
template `ContentView.swift` / app files Xcode generated, or you'll get a
duplicate-`@main` build error.

## 6. Run order
1. Run the **iOS app on a real iPhone** (simulator cannot verify shielding)
2. Request authorization → pick apps → "Shield for 15 min"
3. Open a blocked app. Confirm the shield screen appears.
4. **Force-quit FocusApp.** Wait out the 15 minutes. Confirm the shield lifts.
5. Repeat, rebooting the phone mid-session.
6. Run the **watch target on your Apple Watch**, kill the iOS app, tap "Start 25 min".
   Does the phone wake and shield? Time it.
7. Mid-session, tap "+10 min". Does it throw? **This is the question that matters most.**

## 7. Record everything
Every result — especially the failures — goes in the findings log at the bottom of
`03 Projects/FocusApp/01 Building/(C) Task 0 — Screen Time API Spike (Path B).md`.
Negative results become the README's Limitations section.

## Timebox
**2 sessions.** If acceptance criteria aren't met by then, fall back to Path A.

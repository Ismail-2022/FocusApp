# FocusApp

![CI](https://github.com/Ismail-2022/FocusApp/actions/workflows/ci.yml/badge.svg)

An open-source Apple Watch focus timer that **blocks the distracting apps on your iPhone** for the length of a session. One tap on the wrist, extendable mid-session, and the block lifts automatically when time's up.

> **Status: pre-alpha feasibility spike.** The architecture and safety model are in place; on-device verification is in progress. See [Project status](#project-status).

---

## Why not just use Do Not Disturb?

Because **no third-party app can turn on Do Not Disturb or any Focus mode.** Apple exposes no API for it, on iOS or watchOS. Every "focus" app that claims otherwise is either asking you to wire up a Shortcuts automation yourself, or not doing what it says.

FocusApp uses the **Screen Time APIs** instead — `FamilyControls`, `ManagedSettings` and `DeviceActivity` — to shield the apps you pick for the duration of a session.

This is arguably the better behaviour anyway. Do Not Disturb silences notifications; it does nothing to stop you opening Instagram out of habit. A shield does.

## Architecture

```
Apple Watch  ──WatchConnectivity──▶  iPhone app  ──▶  ManagedSettings (the shield)
  (remote)                           (all logic)
                                          │
                                          └──▶  DeviceActivity schedule
                                                      │
                                                      ▼
                                          FocusMonitor extension
                                          (clears the shield on expiry)
```

Three decisions worth calling out:

**The watch is a remote control, not the brain.** watchOS has no `FamilyControls` framework, so every Screen Time call has to happen on the phone. The watch sends `start` / `extend` / `end` and renders a countdown.

**The OS owns the expiry, not the app.** The shield is lifted by a `DeviceActivityMonitor` extension running in its own process. So the session ends correctly even if the app is force-quit, the phone reboots, or the battery dies. An in-app `Timer` could not make that guarantee.

**The shield fails closed.** `ManagedSettings` changes persist across termination *and* reboot — a shield left behind with no expiry owner would block a user's apps until they deleted FocusApp. So if scheduling an expiry ever fails, the shield is torn down immediately rather than left up. See `SessionController`.

## Running it

### Demo Mode — no Apple Developer account needed

Demo Mode swaps the real shield for a logging stub, so the full app runs in the simulator with no entitlement, no paid membership and no Apple Watch. Same UI, same state machine, same code paths — only the Screen Time calls are faked.

```bash
make setup   # installs XcodeGen, generates the Xcode project
make demo    # builds and launches in the simulator
```

That's it. No `.xcodeproj` in the repo (it's generated from `project.yml`), so there's nothing to merge-conflict or path-break.

### Real Mode — the actual thing

```bash
cp Local.xcconfig.example Local.xcconfig   # add your DEVELOPMENT_TEAM
make build
```

## Prerequisites

| | Demo Mode | Real Mode |
|---|---|---|
| Xcode | ✅ required | ✅ required |
| Apple Developer Program (£79/yr) | — | ✅ required |
| `com.apple.developer.family-controls` entitlement | — | ✅ required (Apple-gated for distribution) |
| Physical iPhone | — | ✅ required (simulator can't shield) |
| Apple Watch | — | ✅ for the watch half |
| Apps actually get blocked | ❌ logged only | ✅ |

**Why no downloadable build?** iOS binaries must be code-signed against a specific team and device list, so there's no executable anyone can just run. Worse, the Family Controls entitlement is **per-team** — even a perfectly signed build wouldn't shield anything under someone else's account. Demo Mode exists precisely because of this.

## Limitations

Honest list, because these are Apple's constraints and not bugs:

- **No Do Not Disturb.** Not possible for third-party apps. App shielding is used instead.
- **A session is 15 minutes minimum** in Real Mode — `DeviceActivitySchedule` rejects shorter intervals. Demo Mode allows shorter sessions so the flow is quick to watch; don't mistake that for the real limit.
- **Selected apps are unreadable to the app.** `ApplicationToken` is opaque by design: no bundle IDs, no names. FocusApp can count your selection and block it, never list or sync it.
- **App picking happens on the phone.** `FamilyActivityPicker` is iOS-only, so the watch can't change which apps are blocked.
- **The monitor extension runs under a ~6 MB memory cap**, so it does exactly one thing: clear the shield.

<!-- TODO: add findings from the on-device spike — extend-under-15-min behaviour, watch wake latency -->

## Project status

- [x] Architecture + safety model
- [x] Demo Mode, reproducible builds, CI
- [ ] On-device verification of the shield and the force-quit failsafe
- [ ] `+10 min` extend under the 15-minute floor — behaviour unknown
- [ ] Watch → phone background wake: reliability and latency
- [ ] Real UI (current UI is a deliberately ugly spike harness)

## Licence

MIT — see [LICENSE](LICENSE).

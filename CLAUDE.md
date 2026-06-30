# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Countdowns is a multiplatform SwiftUI app (iOS, macOS, watchOS, visionOS) that shows a list of upcoming events counting down the days until each. Events come from several sources: built-in common holidays/observances, TMDB movie/TV release dates, imported system calendars, and manually entered custom dates. It is shipped by 256 Arts ([github.com/256Arts/Countdowns](https://github.com/256Arts/Countdowns)).

## Building & Running

This is an Xcode project (`Countdowns.xcodeproj`) — there is no SPM manifest, Makefile, or CI config. Build and run via Xcode, or from the CLI:

```sh
# Build the main app (pass a -destination appropriate for the target platform)
xcodebuild -project Countdowns.xcodeproj -scheme Countdowns build
```

There is no test target, no linter config, and no test suite in this repository.

### Targets

- **Countdowns** — the main app.
- **CountdownsWidgetExtension** — WidgetKit extension (home screen, lock screen accessory, and watch complications).
- **Countdowns Watch Watch App** — standalone watchOS app.
- **TMDb** — external SPM dependency ([adamayoung/TMDb](https://github.com/adamayoung/TMDb)), the only third-party package.

`Countdowns/Models/Secrets.swift` (TMDB API key) is git-ignored — it must exist locally for the app to compile.

## Architecture

### Data model & persistence

`Event` (`Countdowns/Models/Event.swift`) is the single SwiftData `@Model`. Persistence is **SwiftData backed by CloudKit** (container `iCloud.com.256arts.countdowns`), so all `@Model` stored properties must be optional or have defaults (a CloudKit requirement) — note every property on `Event` is optional.

`Event` carries an optional `DataSource` enum that drives how its date is kept up to date:
- `.recurrence(month, day, end)` — yearly events (handles Feb 29 leap years).
- `.movie(id)` / `.tvShow(id)` — TMDB-sourced; **not user-editable** (`isEditable == false`).
- `.calendar(id)` — mirrored from a system `EKCalendar`.
- `nil` — a one-off single event.

Key derived/transient logic lives in computed `@Transient` properties: `daysUntil`, `relevanceScore` (used for widget timeline relevance — do **not** sort by it, since 30+ days collapse to the same value), `subtitle`, and `isTemporaryEstimate`. The `[Event].upcoming` extension is the canonical "what to show" filter+sort (relevance > 0, sorted by `daysUntil`).

### Refresh / fetch flow

`Event.fetch()` (excluded on watchOS via `#if !os(watchOS)`) mutates the event's date in place based on its `DataSource`: it advances recurrences to the next occurrence, and pulls release dates from `MediaDatabase` for movies/TV. Calendar events are deliberately **not** updated one-by-one here — instead the whole calendar is regenerated (see below).

`UpcomingList.refreshEvents()` fans `fetch()` out across all events with a `TaskGroup`, then calls `CalendarService.regenerateCalendarEvents`. This runs on `.task` and `.refreshable`.

### Icons

`IconResource` (`symbolIcon` / `remote` / `preloaded`) is a transient layer over the persisted `iconURL: String`. The getter in `Event.icon` infers the kind from the string: contains `/` → remote URL, otherwise an SF Symbol name. `preloadedIconData` holds downloaded image bytes (TMDB posters) for offline/widget rendering; `preloadImage(large:)` swaps the TMDB poster size in the URL (`/w185/` → `/w500/` or `/w92/`).

### External services

- **MediaDatabase** (`Countdowns/Models/MediaDatabase.swift`) — singleton wrapper over the TMDb SDK. Search filters out already-released movies; TV "release date" is the earliest future season air date.
- **CalendarService** (`Countdowns/Models/CalendarService.swift`) — `@MainActor @Observable` singleton fronting an `actor CalendarStore` that owns the `EKEventStore`. Requires **full** calendar access (write-only is rejected with an `.upgrade` error). `regenerateCalendarEvents` deletes and recreates all `.calendar` events for each synced calendar (within a 3-year window) rather than diffing. It listens for `.EKEventStoreChanged` notifications in `UpcomingList`'s `.task` to stay in sync.

### UI structure

- App entry is `CountdownsApp.swift`: a `NavigationSplitView` with `UpcomingList` as sidebar and `FullScreenEventView` as detail. In `DEBUG` on simulator/macOS it swaps in an in-memory `previewContainer` seeded from `CommonEventsList`.
- `Countdowns/Views/` holds the list/row/detail/picker views; `Countdowns/Views/New Events/` holds the "add event" sheets (common, movie/TV, custom, import calendar, date estimate), launched from the `+` toolbar menu in `UpcomingList`.
- The widget (`CountdownsWidget/CountdownsWidget.swift`) builds its own `ModelContext` against the same CloudKit container and renders different layouts per `WidgetFamily`. Call `WidgetCenter.shared.reloadAllTimelines()` (guarded by `#if canImport(WidgetKit)`) after mutating events so widgets refresh — see the delete buttons in `UpcomingList`.

### Cross-platform conventions

The codebase is heavily conditionally compiled. Common guards: `#if os(macOS)` / `os(watchOS)` / `os(visionOS)` for platform-specific UI and behavior, `#if canImport(UIKit)` vs the AppKit branch for `UIImage`/`NSImage` and system colors, and `#if canImport(WidgetKit)` around widget reloads. The watch app and widget have their own `UpcomingList` / view code separate from the main app's. When touching shared model code, keep the watchOS exclusions (e.g. `Event.fetch()`) in mind.

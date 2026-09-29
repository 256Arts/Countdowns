# Countdowns

<img src="https://www.256arts.com/countdowns/icon_countdowns.png" alt="Countdowns icon" width="128" align="right">

See how many days are left until everything that matters — birthdays, holidays, movie releases, and your own events.

[Download on the App Store](https://apps.apple.com/app/countdowns/id6476715415) · [256arts.com/countdowns](https://www.256arts.com/countdowns/)

<img src="https://www.256arts.com/countdowns/shot1.webp" alt="Countdown widgets on an iOS Home Screen wallpaper" width="300"> <img src="https://www.256arts.com/countdowns/shot3.webp" alt="The upcoming events list showing days remaining for each countdown" width="300">

## Features

- **One list for every countdown** — built-in holidays and observances, movie and TV release dates, your system Calendar events, and custom one-off dates, all sorted by days remaining.
- **Movie & TV release countdowns** — search The Movie Database and add a title; the release date keeps itself up to date.
- **Import from Calendar** — pull events from any calendar on your device and keep them synced automatically.
- **Widgets & complications** — Home Screen and Lock Screen widgets, Apple Watch complications, and a Mac menu bar extra.
- **Notifications** — optional reminders on the day of an event, or the day before.
- **Siri & Shortcuts** — create a countdown, ask how many days until something, or hear your upcoming events by voice.
- **iCloud sync** — countdowns stay up to date across all your devices.
- iPhone, iPad, Mac, Apple Vision Pro, and Apple Watch.

## Building

Open `Countdowns.xcodeproj` in the latest Xcode and run the `Countdowns` scheme. `Countdowns/Models/Secrets.swift` (a TMDB API key) must exist locally for the app to compile. See [`AGENTS.md`](AGENTS.md) for the architecture.

## Credits

Countdowns uses the TMDB API for movie and TV release dates, but is not endorsed or certified by TMDB.

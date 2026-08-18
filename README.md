# DONE:Daily

A simple, focused daily productivity app built around one idea: **plan your day, do the work, then actually stop and rest.**

No bloat. No subscriptions. No ads. Just a clean daily system that respects your time.

---

## What It Does

Most productivity apps make you feel like you're never doing enough. DONE:Daily works differently — it has a clear end to the day built in. You set a work end time, you do your goals, and when the time comes, you wind down and rest. That's it.

---

## Features

### Today Tab
- Add goals for the day and mark them done
- Set one goal as priority
- Reorder goals by drag
- Recurring goals auto-appear on scheduled days
- Incomplete goals carry over to tomorrow as suggestions
- Reflection field — write how the day went
- Work end countdown with wind-down reminder

### Focus Timer
- Preset durations: 5, 15, 25, 45 minutes
- Custom duration (1–180 min)
- Pause and resume
- Focus minutes accumulated and tracked per day

### Wind-Down
- Guided 10-minute breathing routine when work ends
- Optional end-of-day reflection note
- Marks the day as complete

### Calendar Tab
- Monthly calendar view of past and future days
- Mark rest days (holidays, weekends) in advance — up to 12 months ahead
- Tap any day to review goals and add a reflection
- Work schedule settings (work end time)

### Recap Tab
- Today's goal summary and progress
- Total focus time logged
- Goals carrying over to tomorrow
- Notes written for tomorrow
- Preview of tomorrow's recurring goals

### Recurring Goals
- Create habits that repeat on chosen weekdays
- Managed separately from daily goals
- Streak tracking per habit

### Notifications
- Morning reminder to plan your day
- Work end reminder to start winding down
- Weekly summary reminder
- All notifications are local — no server involved

### Settings
- Dark / light mode
- Work end time
- Notification toggles and times
- Export and import data (JSON backup)
- Privacy information

---

## Privacy

Everything is stored **only on your device** using local storage (Hive). The app has no internet permission. No data is ever collected, transmitted, or shared.

Privacy policy: https://cleversta.github.io/done_daily_privacy/

---

## Completely Free

DONE:Daily is free and will always be free. No ads, no premium tier, no subscription of any kind.

If it has helped you and you want to support the developer:
https://cleversta.github.io/about_me/

---

## Tech Stack

- **Flutter** (Dart)
- **flutter_bloc** — state management
- **Hive** — local on-device storage
- **go_router** — navigation
- **flutter_local_notifications** — local notifications
- **flutter_timezone** — correct timezone handling

---

## Build

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build release App Bundle (Play Store)
flutter build appbundle --release
```

Signing is configured via `android/key.properties` (not included in the repo).

---

## About the Developer

DONE:Daily is built by **marason** — a solo developer who builds simple, honest tools.

🔗 https://cleversta.github.io/about_me/

---

## License

All rights reserved © 2026 DONE:Daily.

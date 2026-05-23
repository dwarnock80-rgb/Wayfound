# Wayfound

Wayfound is a calm, local-only goal progress app for busy parents, carers, and people rebuilding routines in chaotic seasons.

## Built From The Product Spec

- Fixed life categories: Health, Money, Family, Purpose, You
- Weighted goals with Partially met, Achieved, and Exceeded check-ins
- Momentum Score instead of brittle streaks
- Recovery Mode for low-consistency periods
- Sleep Mode for holidays, illness, or life events
- Local-only privacy with no accounts or backend
- To-do list, Sleep Mode, local reminders, and settings

## Development

This project is written for Swift 6 and SwiftUI.

Open the iOS app project in Xcode 16 or newer:

```sh
open Wayfound.xcodeproj
```

The app persists data locally as JSON in Application Support. The included
`codemagic.yaml` includes an unsigned CI build and a signed App Store IPA
workflow. Before release, set the final bundle identifier in Codemagic and
App Store Connect, then configure the matching signing integration.

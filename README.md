# Ripplet

The official Koolbase sample app — a real chat application that exercises
every Koolbase feature: Auth, Database, Storage, Realtime, Functions,
Feature Flags, Remote Config, Version Enforcement, and VM-level code push.

## Run it

```bash
flutter run          # zero setup — uses the public Koolbase sample project
```

Requires Flutter 3.44.4 (pinned via FVM: `fvm use`).

## Environments

Configuration is compile-time via `--dart-define` (see `lib/core/env.dart`
and the `Makefile`):

| Command            | Backend                     |
|--------------------|-----------------------------|
| `make run`         | production sample project   |
| `make run-dev`     | local Koolbase (127.0.0.1)  |
| `make run-staging` | staging                     |
| `make run-kobby`   | code-push build on device (forked engine) |

## Structure

Feature-first, thin layers. `data/` is the only place the Koolbase SDK is
imported — read any repository file to learn the SDK.

```
lib/features/<feature>/
  data/           # Koolbase repositories (the SDK examples)
  domain/         # plain Dart models
  application/    # Riverpod providers & notifiers
  presentation/   # widgets only
```

## Build plan

1. Scaffold: theme, router, all 9 screens as stubs
2. Auth (sign in / sign up / session)
3. Profile + avatar upload (Storage)
4. Chat list & user search (Database)
5. Realtime: messages, typing, presence, unread
6. Chat room: send text/image, reactions
7. Feature Flags (Labs) + Remote Config (Appearance)
8. Version Enforcement gate
9. Code-push "improvements applied" banner

# ── Ripplet build entrypoints ──────────────────────────────────────
# Never run bare `flutter run` for code-push work: without the
# local-engine flags you silently get the stock engine and
# applyKoolbasePatch does not exist. Use make run-kobby.

ENGINE_SRC := /Volumes/KoolbaseSSD/koolbase-engine-3444/engine/src

# NOTE: DEV_DEFINES is SIMULATOR-ONLY. 127.0.0.1 on a physical device
# is the device itself — from Kobby, a local API must be reached via
# the Mac's LAN IP instead.
DEV_DEFINES     := --dart-define=KOOLBASE_URL=http://127.0.0.1:8080 --dart-define=KOOLBASE_KEY=dev_local
STAGING_DEFINES := --dart-define=KOOLBASE_URL=https://staging.koolbase.com --dart-define=KOOLBASE_KEY=$(KOOLBASE_STAGING_KEY)

.PHONY: run run-dev run-staging run-prod run-kobby accept-kobby

## Customer path — production sample project, stock engine
run:
	flutter run

## Simulator + locally running API only (see NOTE above)
run-dev:
	flutter run $(DEV_DEFINES)

run-staging:
	flutter run $(STAGING_DEFINES)

run-prod:
	flutter run

## Code-push device build — forked engine, release, on Kobby.
## No defines: uses env.dart defaults (production API + ripple key).
run-kobby:
	flutter run --release \
	  --local-engine-src-path $(ENGINE_SRC) \
	  --local-engine ios_release \
	  --local-engine-host host_release_arm64 \
	  --extra-gen-snapshot-options=--force_indirect_calls \
	  -d Kobby

## Acceptance loop — release build, STOCK engine, on Kobby.
## Any test involving cold launch (session restore, version gate,
## code-push banner) MUST use this: iOS debug builds cannot launch
## from the home screen, so debug mode structurally cannot test
## "kill app, relaunch, see X".
accept-kobby:
	flutter run --release -d Kobby

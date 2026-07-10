# ── Ripplet build entrypoints ──────────────────────────────────────
# Never run bare `flutter run` for code-push work: without the
# local-engine flags you silently get the stock engine and
# applyKoolbasePatch does not exist. Use make run-kobby.

# Overridable: ENGINE_SRC=/path/to/engine/src make run-kobby
ENGINE_SRC ?= /Volumes/KoolbaseSSD/koolbase-engine-3444/engine/src

# NOTE: DEV_DEFINES is SIMULATOR-ONLY. 127.0.0.1 on a physical device
# is the device itself; a local API must be reached via the Mac's
# LAN IP instead.
DEV_DEFINES     := --dart-define=KOOLBASE_URL=http://127.0.0.1:8080 --dart-define=KOOLBASE_KEY=dev_local
STAGING_DEFINES := --dart-define=KOOLBASE_URL=https://staging.koolbase.com --dart-define=KOOLBASE_KEY=$(KOOLBASE_STAGING_KEY)

.PHONY: help run run-dev run-staging run-kobby accept-kobby

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

run: ## Customer path — production project, stock engine, any device
	flutter run

run-dev: ## Simulator + locally running API only (see NOTE above)
	flutter run $(DEV_DEFINES)

run-staging: ## Staging API (requires KOOLBASE_STAGING_KEY in env)
ifndef KOOLBASE_STAGING_KEY
	$(error KOOLBASE_STAGING_KEY is not set)
endif
	flutter run $(STAGING_DEFINES)

run-kobby: ## Code-push build — FORKED engine, release, on Kobby
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
accept-kobby: ## Acceptance — release build, STOCK engine, on Kobby
	flutter run --release -d Kobby

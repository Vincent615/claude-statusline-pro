#!/usr/bin/env bats
#
# Unit tests for the fmt_duration() helper in bin/statusline.sh.
# Verifies both English and 繁體中文 output, and sub-hour vs
# multi-hour formatting.

setup() {
  source "${BATS_TEST_DIRNAME}/../bin/statusline.sh"
}

# ── English ──────────────────────────────────────────────────

@test "fmt_duration en: 0 minutes" {
  LANG_CODE=en
  [ "$(fmt_duration 0)" = "0m" ]
}

@test "fmt_duration en: sub-hour" {
  LANG_CODE=en
  [ "$(fmt_duration 5)" = "5m" ]
}

@test "fmt_duration en: 59m (just below hour)" {
  LANG_CODE=en
  [ "$(fmt_duration 59)" = "59m" ]
}

@test "fmt_duration en: exact hour" {
  LANG_CODE=en
  [ "$(fmt_duration 60)" = "1h0m" ]
}

@test "fmt_duration en: 2h5m" {
  LANG_CODE=en
  [ "$(fmt_duration 125)" = "2h5m" ]
}

# ── 繁體中文 ─────────────────────────────────────────────────

@test "fmt_duration zh: sub-hour (5m label)" {
  LANG_CODE=zh
  [ "$(fmt_duration 5)" = "5分" ]
}

@test "fmt_duration zh: multi-hour (125m label)" {
  LANG_CODE=zh
  [ "$(fmt_duration 125)" = "2時5分" ]
}

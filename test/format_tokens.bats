#!/usr/bin/env bats
#
# Unit tests for the format_tokens() helper in bin/statusline.sh.
# Covers: sub-K passthrough, K/M boundaries, rounding (half-up),
# and the carry edge case where M-minor rounds up to 10.

setup() {
  source "${BATS_TEST_DIRNAME}/../bin/statusline.sh"
}

# ── Sub-K passthrough (no suffix) ────────────────────────────

@test "format_tokens: 0 returns 0" {
  [ "$(format_tokens 0)" = "0" ]
}

@test "format_tokens: 500 returns 500" {
  [ "$(format_tokens 500)" = "500" ]
}

@test "format_tokens: 999 (just below K boundary)" {
  [ "$(format_tokens 999)" = "999" ]
}

# ── K range (no decimal, half-up rounding) ───────────────────

@test "format_tokens: 1000 crosses into K" {
  [ "$(format_tokens 1000)" = "1K" ]
}

@test "format_tokens: 1499 rounds down to 1K" {
  [ "$(format_tokens 1499)" = "1K" ]
}

@test "format_tokens: 1500 rounds up to 2K (half-up)" {
  [ "$(format_tokens 1500)" = "2K" ]
}

@test "format_tokens: 42000 stays in K" {
  [ "$(format_tokens 42000)" = "42K" ]
}

@test "format_tokens: 999999 is 1000K (still below M)" {
  [ "$(format_tokens 999999)" = "1000K" ]
}

# ── M range (one decimal, with carry) ────────────────────────

@test "format_tokens: 1000000 crosses into M" {
  [ "$(format_tokens 1000000)" = "1.0M" ]
}

@test "format_tokens: 1500000 shows 1.5M" {
  [ "$(format_tokens 1500000)" = "1.5M" ]
}

@test "format_tokens: 1950000 triggers carry (2.0M)" {
  # Minor would round to 10 → carry into major
  [ "$(format_tokens 1950000)" = "2.0M" ]
}

@test "format_tokens: 1999999 is 2.0M" {
  [ "$(format_tokens 1999999)" = "2.0M" ]
}

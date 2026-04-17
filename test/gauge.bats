#!/usr/bin/env bats
#
# Tests for gauge rendering — build_gauge() and color_for_pct().
# Assertions work on ANSI-stripped output to check Unicode
# block characters (█, ▁, fractional blocks).

setup() {
  source "${BATS_TEST_DIRNAME}/../bin/statusline.sh"
}

# Strip ANSI escape sequences so we can assert on visible chars
strip_ansi() {
  printf '%s' "$1" | sed $'s/\x1b\\[[0-9;]*m//g'
}

# ── build_gauge: fill-level sanity ───────────────────────────

@test "build_gauge 0: no full blocks" {
  result=$(build_gauge 0 10)
  stripped=$(strip_ansi "$result")
  [[ "$stripped" != *█* ]]
}

@test "build_gauge 100: fully filled, no empty track" {
  result=$(build_gauge 100 10)
  stripped=$(strip_ansi "$result")
  [[ "$stripped" != *▁* ]]
}

@test "build_gauge 50: contains both filled and empty" {
  result=$(build_gauge 50 10)
  stripped=$(strip_ansi "$result")
  [[ "$stripped" == *█* ]]
  [[ "$stripped" == *▁* ]]
}

# ── build_gauge: boundary clamping ───────────────────────────

@test "build_gauge negative clamps to 0" {
  result=$(build_gauge -5 10)
  stripped=$(strip_ansi "$result")
  [[ "$stripped" != *█* ]]
}

@test "build_gauge >100 clamps to 100" {
  result=$(build_gauge 150 10)
  stripped=$(strip_ansi "$result")
  [[ "$stripped" != *▁* ]]
}

@test "build_gauge output is non-empty" {
  [ -n "$(build_gauge 50 10)" ]
}

# ── color_for_pct: clamps & ANSI format ──────────────────────

@test "color_for_pct emits an ANSI escape sequence" {
  result=$(color_for_pct 50)
  # Must start with ESC [ and end with m
  [[ "$result" == $'\x1b['*m ]]
}

@test "color_for_pct: 150 clamps to same color as 100" {
  [ "$(color_for_pct 150)" = "$(color_for_pct 100)" ]
}

@test "color_for_pct: -5 clamps to same color as 0" {
  [ "$(color_for_pct -5)" = "$(color_for_pct 0)" ]
}

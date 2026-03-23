[繁體中文](README.zh-TW.md) | **English**

# ◆ claude-statusline-pro

A real-time terminal dashboard for Claude Code — gradient gauges for context window, rate limits, session cost, and git status. Official API only, zero external calls.

```
◆ Opus 4.6  │  my-app ⎇ main +3~2  │  $2.41 +312/-45  │  ⏱ 1h15m
ctx ▐████▊▁▁▁▁▁▁▁▁▁▌  35%  70K/200K    5h ▐██████▋▁▁▁▁▁▁▌  52%  ⟳ 2h18m    7d ▐██▍▁▁▁▁▁▁▁▁▁▁▌  18%  ⟳ 5d3h
```

## Why This Exists

Claude Code v1.2.80+ provides a `rate_limits` field in the statusline JSON. This means rate limit data is available **without** hitting undocumented APIs, reading OAuth tokens, or accessing the system Keychain.

This project uses **only** that official data.

## Features

- **101-level smooth RGB gradient** gauges with fractional block precision (▏▎▍▌▋▊▉)
- **Rate limits** (5-hour + 7-day) with relative reset countdown (2h18m / 5d3h)
- **Context window** usage with token count (70K/200K)
- **Git branch** + staged/modified file counts (+3~2)
- **Session cost** + lines added/removed ($2.41 +312/-45)
- **Bilingual** — English and 繁體中文, switchable without reinstall
- **Adaptive width** — auto-adjusts gauges for narrow terminals
- **Zero external calls** — no OAuth, no Keychain, no curl. Only official stdin JSON
- **Only 2 dependencies** — jq + git

## Install

```bash
npx claude-statusline-pro          # English
npx claude-statusline-pro --zh     # 繁體中文
```

Restart Claude Code to see the statusline.

## Switch Language

No reinstall needed:

```bash
npx claude-statusline-pro --lang zh    # Switch to 繁體中文
npx claude-statusline-pro --lang en    # Switch to English
```

Takes effect immediately.

## Uninstall

```bash
npx claude-statusline-pro --uninstall
```

Restores your previous statusline if one existed.

## Requirements

- **Claude Code v1.2.80+** (for `rate_limits` field)
- **jq** — JSON processor
- **git** — for branch and status info

```bash
# macOS
brew install jq git

# Ubuntu / Debian
sudo apt install jq git

# Arch
sudo pacman -S jq git
```

## What It Shows

### Line 1 — Session Metadata

| Segment | Example | Description |
|---------|---------|-------------|
| Model | `◆ Opus 4.6` | Current model (prefixes and suffixes stripped) |
| Directory | `my-app ⎇ main +3~2` | Project, git branch, staged (+) / modified (~) |
| Cost | `$2.41 +312/-45` | Session cost + lines added/removed (hidden at $0) |
| Duration | `⏱ 1h15m` | Time since session start |

### Line 2 — Gauges

| Gauge | Example | Description |
|-------|---------|-------------|
| Context | `ctx ▐████▊▁▁▁▁▁▁▁▁▁▌ 35% 70K/200K` | Context window usage + token count |
| 5-hour | `5h ▐██████▋▁▁▁▁▁▁▌ 52% ⟳ 2h18m` | 5-hour rate limit + time until reset |
| 7-day | `7d ▐██▍▁▁▁▁▁▁▁▁▁▁▌ 18% ⟳ 5d3h` | 7-day rate limit + time until reset |

> Rate limit gauges are automatically hidden for API-key billing users.

> Token count is hidden when the terminal is narrower than 100 columns.

### Chinese Labels

| English | 繁體中文 |
|---------|---------|
| `ctx` | `上下文量` |
| `5h` | `5小時用量` |
| `7d` | `週用量` |
| `45m` | `45分` |
| `2h18m` | `2時18分` |
| `5d3h` | `5天3時` |

## Visual Design

### Pixel Matrix Gauge

Each gauge uses a three-layer structure:

```
▐████▊▁▁▁▁▁▁▁▁▁▌
│ ││││ │         │
│ ││││ │         └─ ▌ right frame (dim)
│ ││││ └─ ▁ track (ultra-dark rail)
│ │││└─ ▊ fractional edge (8 levels: ▏▎▍▌▋▊▉█)
│ ││└─ █ filled (per-column RGB gradient)
│ │└─ █ filled
│ └─ █ filled
└─ ▐ left frame (dim)
```

### 101-Level Smooth Gradient

Each filled column gets its own RGB color, interpolated across 6 color stops:

| Range | Color | Hex |
|-------|-------|-----|
| 0–29% | Green | `#50DC82` |
| 30–49% | Lime | `#AADC50` |
| 50–64% | Yellow | `#F0C83C` |
| 65–79% | Orange | `#FFA03C` |
| 80–94% | Red | `#FF5555` |
| 95–100% | Pink | `#FF6496` |

The gradient is generated once at startup (single `awk` call) and cached in a bash array for zero-cost lookups during rendering.

### Fractional Precision

Standard progress bars have resolution equal to their width (13 chars = 13 levels). This tool uses Unicode fractional block elements for **8x precision** (13 chars = 104 levels):

```
▏ = 1/8    ▍ = 3/8    ▋ = 5/8    ▉ = 7/8
▎ = 2/8    ▌ = 4/8    ▊ = 6/8    █ = 8/8
```

## Customization

The script lives at `~/.claude/statusline.sh`. Edit directly.

### Gauge Width

Change `GAUGE_WIDTH` on line 11 (auto-adjusted for narrow terminals):

```bash
GAUGE_WIDTH=13    # Default (104 levels of precision)
GAUGE_WIDTH=20    # Wider (160 levels)
GAUGE_WIDTH=8     # Compact
```

### Colors

Each color is defined as a 24-bit RGB escape code near the top of the script:

```bash
C_BRAND=$'\033[38;2;120;119;255m'    # ◆ model name
C_ACCENT=$'\033[38;2;99;215;190m'    # Directory name
C_BRANCH=$'\033[38;2;130;220;160m'   # Git branch
C_DIRTY=$'\033[38;2;255;140;90m'     # Modified indicator
C_FRAME=$'\033[38;2;42;48;56m'       # Gauge frame ▐▌
C_TRACK=$'\033[38;2;30;34;40m'       # Empty track ▁
```

### Adaptive Width Threshold

The script auto-detects terminal width. Change the threshold on line 16:

```bash
if (( COLS < 100 )); then    # Adjust this number
```

## How It Works

```
Claude Code                         statusline.sh
    │                                    │
    ├─ stdin JSON ──────────────────────►│
    │  model, context, cost,             │ 1. jq parses all fields (single call)
    │  rate_limits, session              │ 2. awk generates 101-color gradient (once)
    │                                    │ 3. git branch + status
    │                                    │ 4. bash arithmetic for gauges (zero forks)
    │                                    │
    │◄──────────────── stdout ANSI ──────┤
    │                                    │
    └─ renders in status bar             └─ exit 0
```

- **Zero external API calls** — all data from Claude Code's stdin JSON
- **Single jq invocation** — 15 fields parsed in one call via Unit Separator
- **No OAuth, no Keychain, no curl** — nothing leaves your machine
- **Graceful degradation** — missing fields silently hidden, never crash

## Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| macOS (Apple Silicon) | Supported | Primary target |
| macOS (Intel) | Supported | |
| Linux (x86_64) | Supported | Ubuntu, Arch tested |
| WSL2 | Supported | Via Windows Terminal |
| Windows (native) | Not supported | Use WSL2 |

Requires a terminal with **24-bit color** support: iTerm2, Ghostty, Alacritty, Kitty, Windows Terminal, GNOME Terminal.

## License

MIT


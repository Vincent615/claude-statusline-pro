# ─────────────────────────────────────────────────────────────
# claude-statusline-pro — user configuration
# ─────────────────────────────────────────────────────────────
#
# Sourced by statusline.sh AFTER defaults are set. Any variable
# you uncomment below overrides the default in statusline.sh.
#
# ⚠  Preserved across `npx claude-statusline-pro` upgrades.
#    Safe to edit — your changes survive.
#
# ─────────────────────────────────────────────────────────────


# ── Basic ────────────────────────────────────────────────────

# Language: "en" (English) or "zh" (繁體中文)
LANG_CODE="en"

# Gauge width in characters (default 13). Auto-shrinks to 8
# when terminal is narrower than NARROW_THRESHOLD.
# GAUGE_WIDTH=13

# Narrow-terminal threshold in columns (default 100).
# Below this width, gauge shrinks and token count hides.
# Set to 0 to disable narrow mode entirely.
# NARROW_THRESHOLD=100


# ── Colors (24-bit RGB) ──────────────────────────────────────
# Format: C_NAME=$'\033[38;2;R;G;Bm'
# Uncomment any line below to override the default.

# Brand & text
# C_BRAND=$'\033[38;2;120;119;255m'    # ◆ model indicator
# C_ACCENT=$'\033[38;2;99;215;190m'    # directory name
# C_TEXT=$'\033[38;2;210;215;220m'     # primary text (cost, tokens)
# C_DIM=$'\033[38;2;100;105;115m'      # separators, reset markers
# C_MUTED=$'\033[38;2;140;145;155m'    # gauge labels (ctx, 5h, 7d)

# Git indicators
# C_BRANCH=$'\033[38;2;130;220;160m'   # ⎇ branch name, staged (+)
# C_DIRTY=$'\033[38;2;255;140;90m'     # modified (~) count

# Gauge chrome
# C_FRAME=$'\033[38;2;42;48;56m'       # gauge frame ▐▌
# C_TRACK=$'\033[38;2;30;34;40m'       # empty track ▁


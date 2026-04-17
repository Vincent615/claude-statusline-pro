#!/bin/bash
# ──────────────────────────────────────────────────────────────
# claude-statusline-pro v2 — Pixel Matrix Edition
# 100% official API · zero external calls · zero OAuth
# ──────────────────────────────────────────────────────────────

# ── Defaults (override in ~/.claude/statusline.config.sh) ────
# Language: "en" (English) or "zh" (繁體中文)
LANG_CODE="en"
# Gauge width (forced to 8 when terminal is narrower than NARROW_THRESHOLD)
GAUGE_WIDTH=13
# Narrow-terminal threshold: below this many columns, gauge shrinks
# and token count is hidden. Set to 0 to disable narrow mode entirely.
NARROW_THRESHOLD=100

# ── Colors (24-bit RGB) — override in config ────────────────
C_BRAND=$'\033[38;2;120;119;255m'
C_ACCENT=$'\033[38;2;99;215;190m'
C_TEXT=$'\033[38;2;210;215;220m'
C_DIM=$'\033[38;2;100;105;115m'
C_MUTED=$'\033[38;2;140;145;155m'
C_BRANCH=$'\033[38;2;130;220;160m'
C_DIRTY=$'\033[38;2;255;140;90m'
C_FRAME=$'\033[38;2;42;48;56m'
C_TRACK=$'\033[38;2;30;34;40m'
C_RESET=$'\033[0m'

# ── Load user config (overrides defaults; survives upgrades) ─
# Edit ~/.claude/statusline.config.sh — npx upgrades only touch
# this script; your config is preserved.
[ -f "$HOME/.claude/statusline.config.sh" ] && source "$HOME/.claude/statusline.config.sh"

# ── Terminal width detection ─────────────────────────────────
COLS=$(tput cols 2>/dev/null || echo 120)
SHOW_TOKENS=1
if (( NARROW_THRESHOLD > 0 && COLS < NARROW_THRESHOLD )); then
  GAUGE_WIDTH=8
  SHOW_TOKENS=0
fi

# ── Dependency check ─────────────────────────────────────────
command -v jq >/dev/null 2>&1 || { echo "◆ install jq for statusline-pro"; exit 0; }

# ── Smooth gradient (101 colors, single awk call) ────────────
GRADIENT=()
while IFS= read -r _line; do
  GRADIENT+=("$_line")
done < <(awk 'BEGIN {
  n=6
  split("0 30 50 65 80 95",sp); split("80 170 240 255 255 255",sr)
  split("220 220 200 160 85 100",sg); split("130 80 60 60 85 150",sb)
  for(p=0;p<=100;p++){
    if(p>=sp[n]){r=sr[n];g=sg[n];b=sb[n]}
    else{for(i=1;i<n;i++){if(p<=sp[i+1]){
      t=(p-sp[i])/(sp[i+1]-sp[i])
      r=int(sr[i]+t*(sr[i+1]-sr[i])+.5)
      g=int(sg[i]+t*(sg[i+1]-sg[i])+.5)
      b=int(sb[i]+t*(sb[i+1]-sb[i])+.5)
      break}}}
    printf "%d;%d;%d\n",r,g,b}}')

FRAC_BLOCKS=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")

# ── Language ─────────────────────────────────────────────────
if [ "$LANG_CODE" = "zh" ]; then
  LBL_CTX="上下文量"; LBL_5H="5小時用量"; LBL_7D="週用量"
else
  LBL_CTX="ctx"; LBL_5H="5h"; LBL_7D="7d"
fi

# ── Helpers ──────────────────────────────────────────────────
color_for_pct() {
  local p=${1:-0}
  (( p > 100 )) && p=100; (( p < 0 )) && p=0
  printf '\033[38;2;%sm' "${GRADIENT[$p]}"
}

format_tokens() {
  local n=${1:-0}
  if   (( n >= 1000000 )); then awk "BEGIN{printf \"%.1fM\",$n/1000000}"
  elif (( n >= 1000 ));    then awk "BEGIN{printf \"%.0fK\",$n/1000}"
  else printf '%s' "$n"
  fi
}

build_gauge() {
  local pct_raw=${1:-0} width=${2:-$GAUGE_WIDTH}
  local pct_int
  pct_int=$(printf '%.0f' "$pct_raw")
  (( pct_int > 100 )) && pct_int=100
  (( pct_int < 0 )) && pct_int=0

  # Sub-character precision: width * 8 levels
  local fill_eighths=$(( pct_int * width * 8 / 100 ))
  local filled=$(( fill_eighths / 8 ))
  local frac_idx=$(( fill_eighths % 8 ))
  (( filled > width )) && filled=$width && frac_idx=0
  local has_frac=0; (( frac_idx > 0 )) && has_frac=1
  local empty=$(( width - filled - has_frac ))
  (( empty < 0 )) && empty=0

  # Left frame
  printf '%b' "${C_FRAME}▐${C_RESET}"

  # Filled: per-column gradient
  local i pos_pct
  for ((i=0; i<filled; i++)); do
    pos_pct=$(( (i + 1) * 100 / width ))
    (( pos_pct > 100 )) && pos_pct=100
    printf '\033[1;38;2;%sm█' "${GRADIENT[$pos_pct]}"
  done

  # Fractional edge
  if (( frac_idx > 0 )); then
    pos_pct=$(( (filled + 1) * 100 / width ))
    (( pos_pct > 100 )) && pos_pct=100
    printf '\033[1;38;2;%sm%s' "${GRADIENT[$pos_pct]}" "${FRAC_BLOCKS[$frac_idx]}"
  fi
  printf '%b' "${C_RESET}"

  # Empty track (▁ = lower 1/8 block → subtle rail)
  if (( empty > 0 )); then
    printf '%b' "${C_TRACK}"
    for ((i=0; i<empty; i++)); do printf '▁'; done
    printf '%b' "${C_RESET}"
  fi

  # Right frame
  printf '%b' "${C_FRAME}▌${C_RESET}"
}


epoch_to_relative() {
  local epoch=${1:-0}
  local now diff
  now=$(date +%s)
  diff=$(( epoch - now ))
  (( diff < 0 )) && diff=0

  local d=$(( diff / 86400 ))
  local h=$(( (diff % 86400) / 3600 ))
  local m=$(( (diff % 3600) / 60 ))

  if [ "$LANG_CODE" = "zh" ]; then
    if   (( d > 0 )); then printf '%d天%d時' "$d" "$h"
    elif (( h > 0 )); then printf '%d時%d分' "$h" "$m"
    else printf '%d分' "$m"; fi
  else
    if   (( d > 0 )); then printf '%dd%dh' "$d" "$h"
    elif (( h > 0 )); then printf '%dh%dm' "$h" "$m"
    else printf '%dm' "$m"; fi
  fi
}

iso_to_epoch() {
  local iso=$1 clean
  clean="${iso%%.*}"; clean="${clean%Z}"
  TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null || \
  date -d "$iso" +%s 2>/dev/null || true
}

fmt_duration() {
  local m=$1
  if [ "$LANG_CODE" = "zh" ]; then
    if (( m >= 60 )); then printf '%d時%d分' "$((m/60))" "$((m%60))"
    else printf '%d分' "$m"; fi
  else
    if (( m >= 60 )); then printf '%dh%dm' "$((m/60))" "$((m%60))"
    else printf '%dm' "$m"; fi
  fi
}

# ── Read input ──────────────────────────────────────────────
input=$(cat)
[ -z "$input" ] && exit 0

# ── Parse JSON (single jq call) ─────────────────────────────
parsed=$(echo "$input" | jq -r '[
  (.model.display_name // "Claude"),
  (.context_window.used_percentage // 0 | tostring),
  (.context_window.context_window_size // 0 | tostring),
  (.context_window.current_usage.input_tokens // 0 | tostring),
  (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring),
  (.context_window.current_usage.cache_read_input_tokens // 0 | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.cost.total_lines_added // 0 | tostring),
  (.cost.total_lines_removed // 0 | tostring),
  (.cwd // .workspace.current_dir // ""),
  (.session.start_time // ""),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring)
] | join("\u001f")' 2>/dev/null) || { echo "◆ statusline-pro"; exit 0; }

IFS=$'\x1f' read -r model_name ctx_pct ctx_size input_tokens cache_create cache_read \
  cost lines_added lines_removed cwd start_time \
  five_h_pct five_h_reset seven_d_pct seven_d_reset <<< "$parsed"

# ── Derived values ──────────────────────────────────────────
short_model="${model_name#Claude }"
short_model="${short_model%% (*}"
ctx_int=${ctx_pct%%.*}; : "${ctx_int:=0}"
total_tokens=$((${input_tokens:-0} + ${cache_create:-0} + ${cache_read:-0}))
dir=""; [ -n "$cwd" ] && dir=$(basename "$cwd")

# ── Git info ────────────────────────────────────────────────
branch="" staged=0 modified=0
if [ -n "$cwd" ] && [ -d "$cwd" ] && \
   git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || true)
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "${line:0:1}" in [MADRC]) staged=$((staged + 1));; esac
    case "${line:1:1}" in [MADRC]) modified=$((modified + 1));; esac
  done < <(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
fi

# ── Session duration ────────────────────────────────────────
duration=""
if [ -n "$start_time" ]; then
  start_epoch=$(iso_to_epoch "$start_time")
  if [ -n "$start_epoch" ]; then
    now=$(date +%s)
    diff_m=$(( (now - start_epoch) / 60 ))
    (( diff_m < 0 )) && diff_m=0
    duration=$(fmt_duration "$diff_m")
  fi
fi

# ── Separator ───────────────────────────────────────────────
SEP="${C_DIM}  │  ${C_RESET}"

# ══════════════════════════════════════════════════════════════
# LINE 1: Metadata
# ══════════════════════════════════════════════════════════════
L1="${C_BRAND}◆ ${short_model}${C_RESET}"

if [ -n "$dir" ]; then
  L1+="${SEP}${C_ACCENT}${dir}${C_RESET}"
  if [ -n "$branch" ]; then
    L1+=" ${C_BRANCH}⎇ ${branch}${C_RESET}"
    (( staged > 0 ))   && L1+=" ${C_BRANCH}+${staged}${C_RESET}"
    (( modified > 0 )) && L1+="${C_DIRTY}~${modified}${C_RESET}"
  fi
fi

cost=${cost:-0}
if awk "BEGIN{exit !($cost > 0)}" 2>/dev/null; then
  cost_fmt=$(awk "BEGIN{printf \"%.2f\",$cost}")
  L1+="${SEP}${C_TEXT}\$${cost_fmt} +${lines_added:-0}/-${lines_removed:-0}${C_RESET}"
fi

[ -n "$duration" ] && L1+="${SEP}${C_TEXT}⏱ ${duration}${C_RESET}"

# ══════════════════════════════════════════════════════════════
# LINE 2: Gauges (all meters aligned)
# ══════════════════════════════════════════════════════════════
L2=""

# Context gauge (always present)
ctx_color=$(color_for_pct "$ctx_int")
ctx_pct_str=$(printf '%3d' "$ctx_int")
tok_used=$(format_tokens "$total_tokens")
tok_max=$(format_tokens "${ctx_size:-0}")
L2+="${C_MUTED}${LBL_CTX}${C_RESET} "
L2+="$(build_gauge "$ctx_int")"
L2+=" ${ctx_color}${ctx_pct_str}%${C_RESET}"
(( SHOW_TOKENS )) && L2+="  ${C_TEXT}${tok_used}/${tok_max}${C_RESET}"

# 5h gauge
if [ -n "$five_h_pct" ]; then
  five_int=$(printf '%.0f' "$five_h_pct")
  five_color=$(color_for_pct "$five_int")
  five_pct_str=$(printf '%3d' "$five_int")
  L2+="    "
  L2+="${C_MUTED}${LBL_5H}${C_RESET} "
  L2+="$(build_gauge "$five_int")"
  L2+=" ${five_color}${five_pct_str}%${C_RESET}"
  if [ -n "$five_h_reset" ]; then
    reset_t=$(epoch_to_relative "$five_h_reset")
    [ -n "$reset_t" ] && L2+="  ${C_DIM}⟳${C_RESET} ${C_TEXT}${reset_t}${C_RESET}"
  fi
fi

# 7d gauge
if [ -n "$seven_d_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_d_pct")
  seven_color=$(color_for_pct "$seven_int")
  seven_pct_str=$(printf '%3d' "$seven_int")
  L2+="    "
  L2+="${C_MUTED}${LBL_7D}${C_RESET} "
  L2+="$(build_gauge "$seven_int")"
  L2+=" ${seven_color}${seven_pct_str}%${C_RESET}"
  if [ -n "$seven_d_reset" ]; then
    reset_d=$(epoch_to_relative "$seven_d_reset")
    [ -n "$reset_d" ] && L2+="  ${C_DIM}⟳${C_RESET} ${C_TEXT}${reset_d}${C_RESET}"
  fi
fi

# ── Output ──────────────────────────────────────────────────
printf '%b' "$L1"
[ -n "$L2" ] && printf '\n%b' "$L2"
exit 0

**繁體中文** | [English](README.md)

# ◆ claude-statusline-pro

[![CI](https://github.com/Vincent615/claude-statusline-pro/actions/workflows/ci.yml/badge.svg)](https://github.com/Vincent615/claude-statusline-pro/actions/workflows/ci.yml)

Claude Code 的即時終端儀表板 — 用漸層進度條顯示上下文用量、API 配額、session 成本和 git 狀態。僅使用官方 API，零外部呼叫。

```
◆ Opus 4.6  │  my-app ⎇ main +3~2  │  $2.41 +312/-45  │  ⏱ 1時15分
上下文量 ▐████▊▁▁▁▁▁▁▁▁▁▌  35%  70K/200K    5小時用量 ▐██████▋▁▁▁▁▁▁▌  52%  ⟳ 2時18分    週用量 ▐██▍▁▁▁▁▁▁▁▁▁▁▌  18%  ⟳ 5天3時
```

## 為什麼做這個

Claude Code v1.2.80 以上版本在 statusline JSON 中提供了 `rate_limits` 欄位。這表示不需要呼叫未公開的 API、不需要讀取 OAuth token、不需要存取系統 Keychain，就能取得用量限制資訊。

本專案**只使用**這些官方資料。

## 功能

- **101 級平滑 RGB 漸層**進度條 + 分數填充精度（▏▎▍▌▋▊▉）
- **用量限制**（5 小時 + 7 天）含相對倒數計時（2時18分 / 5天3時）
- **上下文窗口**用量 + Token 計數（70K/200K）
- **Git 分支** + 暫存/修改檔案數（+3~2）
- **Session 成本** + 新增/刪除行數（$2.41 +312/-45）
- **中英雙語** — 免重裝即可切換
- **自適應寬度** — 自動調整進度條以適應窄終端
- **零外部呼叫** — 不碰 OAuth、Keychain、curl，只讀官方 stdin JSON
- **僅需 2 個依賴** — jq + git

## 安裝

```bash
npx claude-statusline-pro          # English
npx claude-statusline-pro --zh     # 繁體中文
```

安裝後重啟 Claude Code 即可看到狀態列。

## 切換語言

不需要重新安裝：

```bash
npx claude-statusline-pro --lang zh    # 切換為繁體中文
npx claude-statusline-pro --lang en    # 切換為 English
```

立即生效。

## 解除安裝

```bash
npx claude-statusline-pro --uninstall
```

會自動還原先前的 statusline（如果有的話）。

## 系統需求

- **Claude Code v1.2.80+**（需要 `rate_limits` 欄位）
- **jq** — JSON 處理器
- **git** — 取得分支和狀態資訊

```bash
# macOS
brew install jq git

# Ubuntu / Debian
sudo apt install jq git

# Arch
sudo pacman -S jq git
```

## 顯示內容

### 第一行 — Session 資訊

| 區段 | 範例 | 說明 |
|------|------|------|
| 模型 | `◆ Opus 4.6` | 目前使用的模型（自動去除前後綴） |
| 目錄 | `my-app ⎇ main +3~2` | 專案名稱、Git 分支、暫存(+)/修改(~)數 |
| 成本 | `$2.41 +312/-45` | Session 成本 + 新增/刪除行數（$0 時隱藏） |
| 時長 | `⏱ 1時15分` | Session 持續時間 |

### 第二行 — 儀表板

| 儀表 | 範例 | 說明 |
|------|------|------|
| 上下文 | `上下文量 ▐████▊▁▁▁▁▁▁▁▁▁▌ 35% 70K/200K` | 上下文窗口用量 + Token 數 |
| 5 小時 | `5小時用量 ▐██████▋▁▁▁▁▁▁▌ 52% ⟳ 2時18分` | 5 小時用量限制 + 重設倒數 |
| 7 天 | `週用量 ▐██▍▁▁▁▁▁▁▁▁▁▁▌ 18% ⟳ 5天3時` | 7 天用量限制 + 重設倒數 |

> API key 計費用戶不會顯示用量限制儀表。

> 終端寬度小於 100 列時，Token 計數會自動隱藏。

## 視覺設計

### Pixel Matrix 儀表

每個儀表使用三層結構：

```
▐████▊▁▁▁▁▁▁▁▁▁▌
│ ││││ │         │
│ ││││ │         └─ ▌ 右框架（暗色）
│ ││││ └─ ▁ 軌道（極暗底線）
│ │││└─ ▊ 分數邊緣（8 級：▏▎▍▌▋▊▉█）
│ ││└─ █ 填充（逐格 RGB 漸層）
│ │└─ █ 填充
│ └─ █ 填充
└─ ▐ 左框架（暗色）
```

### 101 級平滑漸層

每一格填充都有獨立的 RGB 色彩，在 6 個色標之間平滑插值：

| 範圍 | 顏色 | 色碼 |
|------|------|------|
| 0–29% | 綠色 | `#50DC82` |
| 30–49% | 黃綠 | `#AADC50` |
| 50–64% | 黃色 | `#F0C83C` |
| 65–79% | 橘色 | `#FFA03C` |
| 80–94% | 紅色 | `#FF5555` |
| 95–100% | 粉紅 | `#FF6496` |

漸層表在啟動時一次性生成（單次 `awk` 呼叫），存入 bash 陣列供後續零成本查找。

### 分數精度

一般進度條的解析度等於寬度（13 格 = 13 級）。本工具使用 Unicode 分數方塊元素，達到 **8 倍精度**（13 格 = 104 級）：

```
▏ = 1/8    ▍ = 3/8    ▋ = 5/8    ▉ = 7/8
▎ = 2/8    ▌ = 4/8    ▊ = 6/8    █ = 8/8
```

## 自訂

所有使用者可調整的設定都放在 `~/.claude/statusline.config.sh` — 這是主腳本在套用 defaults 後會 source 的 bash 檔。在此檔設定的任何變數都會 override 預設值。

> **升級會保留你的 config。** 再次執行 `npx claude-statusline-pro` 只會更新 `statusline.sh`，不會動 `statusline.config.sh`。

### 儀表寬度

```bash
# ~/.claude/statusline.config.sh
GAUGE_WIDTH=20    # 更寬（160 級精度）
GAUGE_WIDTH=8     # 精簡
```

### 顏色

每種顏色以 24-bit RGB 定義。在 `statusline.config.sh` 取消註解任一變數即可 override：

```bash
# ~/.claude/statusline.config.sh
C_BRAND=$'\033[38;2;120;119;255m'    # ◆ 模型名稱
C_ACCENT=$'\033[38;2;99;215;190m'    # 目錄名稱
C_BRANCH=$'\033[38;2;130;220;160m'   # Git 分支
C_DIRTY=$'\033[38;2;255;140;90m'     # 修改指標
C_FRAME=$'\033[38;2;42;48;56m'       # 儀表框架 ▐▌
C_TRACK=$'\033[38;2;30;34;40m'       # 空白軌道 ▁
```

### 自適應寬度門檻

```bash
# ~/.claude/statusline.config.sh
NARROW_THRESHOLD=80    # 低於 80 欄觸發窄模式
NARROW_THRESHOLD=0     # 完全停用窄模式
```

## 運作原理

```
Claude Code                         statusline.sh
    │                                    │
    ├─ stdin JSON ──────────────────────►│
    │  model, context, cost,             │ 1. jq 解析所有欄位（單次呼叫）
    │  rate_limits, session              │ 2. awk 生成 101 色漸層表（一次性）
    │                                    │ 3. git 取得分支 + 狀態
    │                                    │ 4. bash 算術渲染儀表（零 fork）
    │                                    │
    │◄──────────────── stdout ANSI ──────┤
    │                                    │
    └─ 顯示於狀態列                       └─ exit 0
```

- **零外部 API 呼叫** — 所有資料來自 Claude Code 的 stdin JSON
- **單次 jq 呼叫** — 15 個欄位透過 Unit Separator 一次解析
- **不碰 OAuth、Keychain、curl** — 沒有任何東西離開你的電腦
- **優雅降級** — 缺少的欄位靜默隱藏，絕不崩潰

## 相容性

| 平台 | 狀態 | 備註 |
|------|------|------|
| macOS (Apple Silicon) | 支援 | 主要開發目標 |
| macOS (Intel) | 支援 | |
| Linux (x86_64) | 支援 | Ubuntu、Arch 測試通過 |
| WSL2 | 支援 | 透過 Windows Terminal |
| Windows (原生) | 不支援 | 請使用 WSL2 |

需要支援 **24-bit 色彩**的終端：iTerm2、Ghostty、Alacritty、Kitty、Windows Terminal、GNOME Terminal。

## 授權

MIT

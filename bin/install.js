#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

// ── Colors ──────────────────────────────────────────────────
const c = {
  brand:  '\x1b[38;2;120;119;255m',
  green:  '\x1b[38;2;80;220;130m',
  yellow: '\x1b[38;2;240;200;60m',
  red:    '\x1b[38;2;255;85;85m',
  dim:    '\x1b[38;2;100;105;115m',
  text:   '\x1b[38;2;210;215;220m',
  bold:   '\x1b[1m',
  reset:  '\x1b[0m',
};

const log = (msg) => console.log(msg);
const ok   = (msg) => log(`  ${c.green}✓${c.reset} ${msg}`);
const warn = (msg) => log(`  ${c.yellow}!${c.reset} ${msg}`);
const fail = (msg) => log(`  ${c.red}✗${c.reset} ${msg}`);

// ── Paths ───────────────────────────────────────────────────
const HOME = os.homedir();
const CLAUDE_DIR = path.join(HOME, '.claude');
const TARGET = path.join(CLAUDE_DIR, 'statusline.sh');
const BACKUP = TARGET + '.bak';
const SETTINGS = path.join(CLAUDE_DIR, 'settings.json');
const SOURCE = path.join(__dirname, 'statusline.sh');

// ── Helpers ─────────────────────────────────────────────────
function commandExists(cmd) {
  try {
    execFileSync('which', [cmd], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function readJson(filepath) {
  try {
    return JSON.parse(fs.readFileSync(filepath, 'utf8'));
  } catch {
    return {};
  }
}

function writeJson(filepath, obj) {
  fs.writeFileSync(filepath, JSON.stringify(obj, null, 2) + '\n', 'utf8');
}

// ── Install ─────────────────────────────────────────────────
function install() {
  log('');
  log(`  ${c.brand}${c.bold}◆ claude-statusline-pro${c.reset}`);
  log(`  ${c.dim}Premium statusline for Claude Code${c.reset}`);
  log('');

  // Check dependencies
  log(`  ${c.dim}Checking dependencies...${c.reset}`);
  let missing = false;

  if (commandExists('jq')) {
    ok('jq found');
  } else {
    fail('jq not found');
    log(`    ${c.dim}Install: brew install jq (macOS) / sudo apt install jq (Linux)${c.reset}`);
    missing = true;
  }

  if (commandExists('git')) {
    ok('git found');
  } else {
    fail('git not found');
    log(`    ${c.dim}Install: brew install git (macOS) / sudo apt install git (Linux)${c.reset}`);
    missing = true;
  }

  if (missing) {
    log('');
    fail('Missing dependencies. Install them and try again.');
    process.exit(1);
  }

  log('');
  log(`  ${c.dim}Installing statusline...${c.reset}`);

  // Ensure ~/.claude/ exists
  if (!fs.existsSync(CLAUDE_DIR)) {
    fs.mkdirSync(CLAUDE_DIR, { recursive: true });
    ok('Created ~/.claude/');
  }

  // Backup existing statusline
  if (fs.existsSync(TARGET)) {
    fs.copyFileSync(TARGET, BACKUP);
    ok('Backed up existing statusline.sh → statusline.sh.bak');
  }

  // Copy script
  fs.copyFileSync(SOURCE, TARGET);
  fs.chmodSync(TARGET, 0o755);

  // Apply language setting
  const isZh = args.includes('--zh') || args.includes('--chinese');
  if (isZh) {
    let content = fs.readFileSync(TARGET, 'utf8');
    content = content.replace('LANG_CODE="en"', 'LANG_CODE="zh"');
    fs.writeFileSync(TARGET, content, 'utf8');
    ok('Installed statusline.sh → ~/.claude/statusline.sh (繁體中文)');
  } else {
    ok('Installed statusline.sh → ~/.claude/statusline.sh (English)');
  }

  // Update settings.json
  const settings = readJson(SETTINGS);
  settings.statusLine = {
    type: 'command',
    command: 'bash "$HOME/.claude/statusline.sh"',
    padding: 0,
  };
  writeJson(SETTINGS, settings);
  ok('Updated ~/.claude/settings.json');

  // Success
  log('');
  log(`  ${c.brand}${c.bold}◆${c.reset} ${c.green}Installation complete!${c.reset}`);
  log('');
  log(`  ${c.text}Features:${c.reset}`);
  log(`    ${c.brand}•${c.reset} ${c.text}Model name + context window progress bar${c.reset}`);
  log(`    ${c.brand}•${c.reset} ${c.text}Rate limits (5h + 7d) with reset timers${c.reset}`);
  log(`    ${c.brand}•${c.reset} ${c.text}Git branch + staged/modified counts${c.reset}`);
  log(`    ${c.brand}•${c.reset} ${c.text}Session cost + lines changed${c.reset}`);
  log(`    ${c.brand}•${c.reset} ${c.text}Session duration${c.reset}`);
  log('');
  log(`  ${c.dim}Restart Claude Code to see your new statusline.${c.reset}`);
  log('');
}

// ── Uninstall ───────────────────────────────────────────────
function uninstall() {
  log('');
  log(`  ${c.brand}${c.bold}◆ claude-statusline-pro${c.reset} ${c.dim}uninstall${c.reset}`);
  log('');

  // Restore backup or delete
  if (fs.existsSync(BACKUP)) {
    fs.copyFileSync(BACKUP, TARGET);
    fs.unlinkSync(BACKUP);
    ok('Restored previous statusline.sh from backup');
  } else if (fs.existsSync(TARGET)) {
    fs.unlinkSync(TARGET);
    ok('Removed ~/.claude/statusline.sh');
  } else {
    warn('No statusline.sh found — nothing to remove');
  }

  // Remove statusLine from settings
  if (fs.existsSync(SETTINGS)) {
    const settings = readJson(SETTINGS);
    if ('statusLine' in settings) {
      delete settings.statusLine;
      writeJson(SETTINGS, settings);
      ok('Removed statusLine from ~/.claude/settings.json');
    }
  }

  log('');
  log(`  ${c.green}Uninstall complete.${c.reset} ${c.dim}Restart Claude Code to apply.${c.reset}`);
  log('');
}

// ── Switch language ──────────────────────────────────────────
function switchLang(lang) {
  log('');
  if (!fs.existsSync(TARGET)) {
    fail('statusline.sh not found — run npx claude-statusline-pro first');
    process.exit(1);
  }

  let content = fs.readFileSync(TARGET, 'utf8');
  content = content.replace(/LANG_CODE="(en|zh)"/, `LANG_CODE="${lang}"`);
  fs.writeFileSync(TARGET, content, 'utf8');

  const label = lang === 'zh' ? '繁體中文' : 'English';
  ok(`Switched to ${label}`);
  log(`  ${c.dim}Takes effect immediately — no restart needed.${c.reset}`);
  log('');
}

// ── Main ────────────────────────────────────────────────────
const args = process.argv.slice(2);
const langIdx = args.indexOf('--lang');
const langArg = langIdx >= 0 ? args[langIdx + 1] : null;

if (langArg === 'zh' || langArg === 'en') {
  switchLang(langArg);
} else if (args.includes('--uninstall') || args.includes('-u')) {
  uninstall();
} else if (args.includes('--help') || args.includes('-h')) {
  log('');
  log(`  ${c.brand}◆ claude-statusline-pro${c.reset}`);
  log('');
  log(`  ${c.text}Usage:${c.reset}`);
  log(`    npx claude-statusline-pro              ${c.dim}Install (English)${c.reset}`);
  log(`    npx claude-statusline-pro --zh         ${c.dim}Install (繁體中文)${c.reset}`);
  log(`    npx claude-statusline-pro --lang zh    ${c.dim}Switch to 繁體中文${c.reset}`);
  log(`    npx claude-statusline-pro --lang en    ${c.dim}Switch to English${c.reset}`);
  log(`    npx claude-statusline-pro --uninstall  ${c.dim}Restore previous statusline${c.reset}`);
  log('');
} else {
  install();
}

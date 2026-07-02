#!/usr/bin/env bash
# Hermos System Audit — scripts/system-audit.sh
# Comprehensive health + integration check across all system domains.
# Run from Mac — SSH handles Windows-side checks automatically.
#
# Usage:
#   ./scripts/system-audit.sh              # full audit
#   ./scripts/system-audit.sh --mac-only   # skip SSH/Windows checks
#   ./scripts/system-audit.sh --quick      # skip slow SSH/data checks
#
# Exit codes: 0=clean, 1=failures, 2=warnings only

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

MAC_ONLY=false
QUICK=false
for arg in "${@:-}"; do
  [[ "$arg" == "--mac-only" ]] && MAC_ONLY=true
  [[ "$arg" == "--quick"    ]] && QUICK=true
done

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'
BLU='\033[0;34m'; DIM='\033[2m'; NC='\033[0m'

FAIL_COUNT=0; WARN_COUNT=0; PASS_COUNT=0; SKIP_COUNT=0

pass()    { echo -e "  ${GRN}✓${NC} $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail()    { echo -e "  ${RED}✗${NC} $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
warn()    { echo -e "  ${YEL}△${NC} $1"; WARN_COUNT=$((WARN_COUNT+1)); }
skip()    { echo -e "  ${DIM}○ $1 [SKIP]${NC}"; SKIP_COUNT=$((SKIP_COUNT+1)); }
section() { echo -e "\n${BLU}▶ $1${NC}"; }

# ── Load secrets from SOPS ───────────────────────────────────────────────────
N8N_API_KEY=""; QS_API_KEY=""
SOPS_FILE="$REPO_ROOT/secrets.enc.json"
if command -v sops &>/dev/null && [[ -f "$SOPS_FILE" ]]; then
  SECRETS=$(sops -d "$SOPS_FILE" 2>/dev/null || echo "{}")
  N8N_API_KEY=$(echo "$SECRETS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('n8n_api_key',''))" 2>/dev/null || true)
  QS_API_KEY=$(echo "$SECRETS"  | python3 -c "import sys,json; print(json.load(sys.stdin).get('qs_api_key',''))"  2>/dev/null || true)
fi

win_ssh() {
  # Capture Windows SSH output; use 2>&1 so pm2/docker stderr doesn't silently drop output
  ssh -o ConnectTimeout=10 -o BatchMode=yes windows-devos "$1" 2>&1 | tr -d '\r' || true
}

# ── Helpers ───────────────────────────────────────────────────────────────────
check_url() {
  local label="$1" url="$2"
  local code
  code=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null || echo "000")
  if [[ "$code" =~ ^[23] ]]; then pass "$label (HTTP $code)"
  else fail "$label — HTTP $code (url: $url)"; fi
}

win_cmd() {
  # Run a powershell command on Windows via SSH, return stdout
  ssh -o ConnectTimeout=10 -o BatchMode=yes windows-devos "powershell -NonInteractive -Command \"$1\"" 2>/dev/null \
    | tr -d '\r' || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 1 — SSH Connectivity
# ═══════════════════════════════════════════════════════════════════════════════
section "SSH Connectivity"
SSH_OK=false
if [[ "$MAC_ONLY" == "true" ]]; then
  skip "SSH checks disabled (--mac-only)"
elif ssh -o ConnectTimeout=8 -o BatchMode=yes windows-devos "echo ok" 2>/dev/null | grep -q "ok"; then
  pass "ssh windows-devos (Cloudflare Tunnel)"
  SSH_OK=true
else
  fail "ssh windows-devos — tunnel down or cloudflared not running"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 2 — External Services (GitHub)
# ═══════════════════════════════════════════════════════════════════════════════
section "External Services (GitHub)"
if command -v gh &>/dev/null; then
  HOOKS=$(gh api repos/eli-herman/hermos/hooks 2>/dev/null || echo "[]")
  HOOK_COUNT=$(echo "$HOOKS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")

  if [[ "$HOOK_COUNT" -eq 0 ]]; then
    fail "No webhooks found on eli-herman/hermos"
  else
    HOOK_ID=$(echo "$HOOKS"   | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)
    HOOK_URL=$(echo "$HOOKS"  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['config']['url'])" 2>/dev/null)
    HOOK_ACT=$(echo "$HOOKS"  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['active'])" 2>/dev/null)
    LAST_CODE=$(echo "$HOOKS" | python3 -c "import sys,json; print(json.load(sys.stdin)[0].get('last_response',{}).get('code','?'))" 2>/dev/null)

    [[ "$HOOK_ACT" == "True" ]] \
      && pass "Webhook active → $HOOK_URL (last: HTTP $LAST_CODE)" \
      || fail "Webhook exists but inactive → $HOOK_URL"

    RECENT_FAILS=$(gh api "repos/eli-herman/hermos/hooks/$HOOK_ID/deliveries" 2>/dev/null \
      | python3 -c "import sys,json; d=json.load(sys.stdin)[:10]; print(len([x for x in d if x.get('status_code',200)>=500]))" 2>/dev/null || echo "?")
    [[ "$RECENT_FAILS" == "0" ]] \
      && pass "Webhook deliveries: no 500s in last 10" \
      || warn "Webhook deliveries: $RECENT_FAILS error(s) in last 10 — check GitHub → Settings → Webhooks"
  fi

  # Repo name sanity
  REPO_NAME=$(gh api repos/eli-herman/hermos 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','?'))" 2>/dev/null || echo "?")
  [[ "$REPO_NAME" == "hermos" ]] && pass "GitHub repo name: hermos" || warn "GitHub repo name: $REPO_NAME (expected hermos)"
else
  skip "gh CLI not found"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 3 — Live Service Health (Cloudflare Tunnel)
# ═══════════════════════════════════════════════════════════════════════════════
section "Live Service Health (Cloudflare Tunnel)"
check_url "Quality Server  /health"      "https://qs.dev-os.dev/health"
check_url "ChromaDB        /api/v2/heartbeat" "https://chromadb.dev-os.dev/api/v2/heartbeat"
check_url "Mem0            /health"      "https://mem0.dev-os.dev/health"
check_url "n8n             dashboard"    "https://n8n.dev-os.dev"
check_url "Claude Bridge   /health"      "https://claude-bridge.dev-os.dev/health"
check_url "Auto-Sync       /health"      "https://sync.dev-os.dev/health"

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 4 — Data Integrity
# ═══════════════════════════════════════════════════════════════════════════════
section "Data Integrity"

if [[ "$QUICK" == "false" ]]; then
  # ChromaDB collection counts vs known baselines
  CHROMA_BASE="https://chromadb.dev-os.dev/api/v2/tenants/default_tenant/databases/default_database"
  COLLECTIONS=$(curl -sf --max-time 10 "$CHROMA_BASE/collections" 2>/dev/null || echo "[]")

  for entry in "hermos:13000" "codebase:6000" "patterns:100"; do
    col_name="${entry%%:*}"; baseline="${entry##*:}"
    COL_ID=$(echo "$COLLECTIONS" | python3 -c "
import sys,json
cols=json.load(sys.stdin)
c=[x for x in cols if x.get('name')=='$col_name']
print(c[0]['id'] if c else '')" 2>/dev/null || true)
    if [[ -z "$COL_ID" ]]; then
      fail "ChromaDB collection '$col_name' missing"
    else
      COUNT=$(curl -sf --max-time 10 "$CHROMA_BASE/collections/$COL_ID/count" 2>/dev/null || echo "0")
      if [[ "${COUNT:-0}" -ge "$baseline" ]]; then
        pass "ChromaDB '$col_name': $COUNT docs (≥$baseline)"
      else
        warn "ChromaDB '$col_name': $COUNT docs (below $baseline baseline)"
      fi
    fi
  done

  # Check no old 'dev-os' collection names remain (rebrand)
  OLD_COLL=$(echo "$COLLECTIONS" | python3 -c "
import sys,json
cols=json.load(sys.stdin)
old=[c['name'] for c in cols if 'dev-os' in c.get('name','')]
print(old)" 2>/dev/null || echo "[]")
  [[ "$OLD_COLL" == "[]" ]] && pass "ChromaDB: no stale 'dev-os' collection names" || fail "ChromaDB: old-named collections found: $OLD_COLL"
else
  skip "ChromaDB counts (--quick)"
fi

# n8n integrity
if [[ -n "$N8N_API_KEY" ]]; then
  N8N_DATA=$(curl -sf --max-time 10 "https://n8n.dev-os.dev/api/v1/workflows?limit=100" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" 2>/dev/null || echo '{"data":[]}')
  WF_COUNT=$(echo "$N8N_DATA" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null || echo "0")
  [[ "$WF_COUNT" -ge 29 ]] && pass "n8n workflows: $WF_COUNT (≥29)" || warn "n8n workflows: $WF_COUNT (expected ≥29)"

  # Lesson 096: genericAuthType must be "Header Auth" not "headerAuth"
  BAD_AUTH=$(echo "$N8N_DATA" | python3 -c "
import sys,json
d=json.load(sys.stdin)
bad=[wf['name'] for wf in d.get('data',[])
     for node in wf.get('nodes',[])
     if node.get('parameters',{}).get('genericAuthType')=='headerAuth']
print(len(bad))" 2>/dev/null || echo "0")
  [[ "${BAD_AUTH:-0}" -eq 0 ]] \
    && pass "n8n: no Lesson-096 headerAuth violations" \
    || fail "n8n: $BAD_AUTH workflow(s) with 'headerAuth' — run credential fix (Lesson 096)"

  # DEVOS_WEBHOOK_SECRET references in workflow nodes
  DEVOS_WF=$(echo "$N8N_DATA" | python3 -c "
import sys,json
raw=sys.stdin.read()
import re
hits=re.findall(r'DEVOS_WEBHOOK_SECRET',raw)
print(len(hits))" 2>/dev/null || echo "0")
  [[ "${DEVOS_WF:-0}" -eq 0 ]] \
    && pass "n8n: no stale DEVOS_WEBHOOK_SECRET references" \
    || fail "n8n: $DEVOS_WF DEVOS_WEBHOOK_SECRET reference(s) found — update workflows"
else
  skip "n8n API key not in SOPS — skipping n8n integrity checks"
fi

# Mem0 memory count
MEM0_COUNT=$(curl -sf --max-time 8 "https://mem0.dev-os.dev/v1/memories/?user_id=hermos" 2>/dev/null \
  | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('results',[])))" 2>/dev/null || echo "-1")
if [[ "$MEM0_COUNT" -ge 0 ]]; then
  pass "Mem0 hermos namespace: $MEM0_COUNT memories"
else
  warn "Mem0 count check failed — is Mem0 reachable?"
fi

# Stale dev-os-system mem0 namespace
STALE_MEM=$(curl -sf --max-time 8 "https://mem0.dev-os.dev/v1/memories/?user_id=dev-os-system" 2>/dev/null \
  | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('results',[])))" 2>/dev/null || echo "0")
[[ "${STALE_MEM:-0}" -eq 0 ]] \
  && pass "Mem0 dev-os-system namespace: empty (clean)" \
  || warn "Mem0 dev-os-system namespace: $STALE_MEM stale memories — migrate to hermos"

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 5 — Windows State (via SSH)
# ═══════════════════════════════════════════════════════════════════════════════
section "Windows State (via SSH)"
if [[ "$SSH_OK" == "true" ]] && [[ "$QUICK" == "false" ]]; then

  # pm2 services — expected ONLINE: mem0-server, n8n, auto-sync-server, windows-claude-bridge, memory-watcher, caddy
  # expected STOPPED by design: cloudflare-health (cron), ollama-warmup (cron), chromadb/quality-server (Docker owns ports)
  PM2_LIST=$(win_ssh "pm2 list --no-color")
  for svc in "mem0-server" "n8n" "auto-sync-server" "windows-claude-bridge" "memory-watcher" "caddy"; do
    SVC_LINE=$(echo "$PM2_LIST" | grep "│ ${svc} " || true)
    if echo "$SVC_LINE" | grep -q "online"; then
      RESTART_COUNT=$(echo "$SVC_LINE" | grep -oE '│ [0-9]+ +│' | grep -oE '[0-9]+' | head -1 || echo "0")
      if [[ "${RESTART_COUNT:-0}" -gt 20 ]]; then
        warn "pm2: $svc online but ${RESTART_COUNT} lifetime restarts — check: pm2 logs $svc"
      else
        pass "pm2: $svc online"
      fi
    elif [[ -n "$SVC_LINE" ]]; then
      STATUS=$(echo "$SVC_LINE" | grep -oE 'online|stopped|errored|waiting' | head -1 || echo "?")
      warn "pm2: $svc status='$STATUS' (expected online)"
    else
      fail "pm2: $svc not found in pm2 list"
    fi
  done

  # Docker containers — compose prefixes names: quality-server-{service}-1
  DOCKER_PS=$(win_ssh "wsl -d Ubuntu -- docker ps --format '{{.Names}} {{.Status}}'")
  for container in "chromadb" "quality-server" "caddy" "diun"; do
    CONTAINER_LINE=$(echo "$DOCKER_PS" | grep "$container" || true)
    if [[ -n "$CONTAINER_LINE" ]] && echo "$CONTAINER_LINE" | grep -q "Up"; then
      pass "Docker: $container running"
    elif [[ -n "$CONTAINER_LINE" ]]; then
      warn "Docker: $container found but not Up — $(echo "$CONTAINER_LINE" | cut -c1-60)"
    else
      fail "Docker: $container not running (not in docker ps)"
    fi
  done

  # Datadog Agent
  DD_STATUS=$(win_cmd "(Get-Service DatadogAgent -ErrorAction SilentlyContinue).Status")
  [[ "${DD_STATUS:-}" == "Running" ]] \
    && pass "Datadog Agent: Running" \
    || fail "Datadog Agent: '${DD_STATUS:-not found}' (expected Running)"

  # Task Scheduler boot tasks (Lesson 078/079)
  for task in "PM2-Startup" "Tailscale-Up"; do
    TASK_STATE=$(win_cmd "(Get-ScheduledTask -TaskName '$task' -ErrorAction SilentlyContinue).State")
    [[ "${TASK_STATE:-}" == "Ready" ]] \
      && pass "Task Scheduler: $task Ready" \
      || warn "Task Scheduler: $task — '${TASK_STATE:-not found}' (expected Ready)"
  done

  # WSL2 keepalive (Lesson 067)
  WSL_PROCS=$(win_cmd "(Get-Process -Name wsl -ErrorAction SilentlyContinue | Measure-Object).Count")
  [[ "${WSL_PROCS:-0}" -gt 0 ]] \
    && pass "WSL2 keepalive: ${WSL_PROCS} wsl process(es) running" \
    || warn "WSL2 keepalive not detected — Docker may stop when WSL2 idles (Lesson 067)"

elif [[ "$QUICK" == "true" ]]; then
  skip "Windows state checks (--quick)"
else
  skip "Windows state checks (SSH unavailable)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 6 — Code Security
# ═══════════════════════════════════════════════════════════════════════════════
section "Code Security"
cd "$REPO_ROOT"

# --- 6a. Gitleaks — full history scan (catches AI-generated credentials committed in any past session) ---
if command -v gitleaks &>/dev/null; then
  GL_OUT=$(gitleaks detect --source . --no-banner --log-opts="--all" 2>&1 | tail -1)
  if echo "$GL_OUT" | grep -q "no leaks found"; then
    pass "gitleaks: full history clean ($(echo "$GL_OUT" | grep -oE '[0-9]+ commits' || echo 'all commits') scanned)"
  else
    LEAK_COUNT=$(echo "$GL_OUT" | grep -oE '[0-9]+ leak' | head -1 || echo "unknown")
    fail "gitleaks: $LEAK_COUNT in full history — run: gitleaks detect --log-opts='--all' --report-format json --report-path /tmp/gl.json"
  fi
else
  warn "gitleaks not installed — install with: brew install gitleaks"
fi

# --- 6b. AI-prone secret patterns in high-risk files (HANDOFF, docs, workflow exports) ---
# These files are written by AI with live context — highest risk of accidental credential inclusion.
AI_FILES=$(git ls-files 2>/dev/null | grep -E "HANDOFF\.md|docs/guides/|docs/b2b/|patterns/tracker\.json|n8n-exports/.*\.json" || true)
if [[ -n "$AI_FILES" ]]; then
  AI_SECRET_HITS=$(echo "$AI_FILES" \
    | xargs grep -lE \
      "\"API_HASH\"\s*:\s*\"[a-f0-9]{32}\"|\"API_ID\"\s*:\s*\"[0-9]{6,}\"|eyJhbGciOiJIUzI1NiIs[a-zA-Z0-9._-]{20,}|['\"]?[a-f0-9]{64}['\"]?\s*(,|$)" \
    2>/dev/null | grep -vE "PLACEHOLDER|your_api|<your|REDACTED" || true)
  [[ -z "$AI_SECRET_HITS" ]] \
    && pass "AI-generated files: no hardcoded credentials detected" \
    || fail "Hardcoded credentials in AI-generated files: $(echo "$AI_SECRET_HITS" | tr '\n' ' ')"
else
  pass "AI-generated files: none tracked"
fi

# --- 6c. n8n workflow exports — embedded JavaScript secrets ---
N8N_EXPORT_HITS=$(git ls-files "n8n-exports/*.json" 2>/dev/null \
  | xargs grep -lE "const AUTH\s*=\s*['\"][a-f0-9]{32,}|const.*[Tt]oken\s*=\s*['\"][a-zA-Z0-9]{20,}|X-DevOS-Auth.*[a-f0-9]{32,}" \
  2>/dev/null || true)
[[ -z "$N8N_EXPORT_HITS" ]] \
  && pass "n8n exports: no embedded auth tokens in JavaScript" \
  || fail "Hardcoded token in n8n export: $(echo "$N8N_EXPORT_HITS" | tr '\n' ' ') — rotate token and scrub file"

# --- 6d. Broad secret patterns in all tracked source files ---
SECRET_HITS=$(git ls-files 2>/dev/null \
  | grep -vE "\.enc\.|system-audit\.sh|lessons-learned\.md|gitleaks\.toml" \
  | xargs grep -lE \
    "ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{32}|\"API_HASH\"\s*:\s*\"[a-f0-9]{32}\"" \
  2>/dev/null \
  | grep -vE "PLACEHOLDER|your_api|<your|REDACTED" || true)
[[ -z "$SECRET_HITS" ]] \
  && pass "No raw secret patterns in tracked source files" \
  || fail "Potential secrets in tracked files: $(echo "$SECRET_HITS" | tr '\n' ' ')"

# --- 6e. .gitignore coverage ---
for pattern in "backup/" "dist/" "\.env" "node_modules" "HANDOFF\.md"; do
  grep -qE "$pattern" .gitignore 2>/dev/null \
    && pass ".gitignore covers: $pattern" \
    || warn ".gitignore missing coverage for: $pattern"
done

# --- 6f. Backslash paths in execSync/spawn (bridge SOPS bug pattern) ---
BS_HITS=$(grep -rn "execSync\|spawnSync" \
  windows-claude-bridge/src/ quality-server/auto-sync-server.js 2>/dev/null \
  | grep -E "'[A-Z]:\\\\|\"[A-Z]:\\\\" | grep -v "//.*execSync" || true)
[[ -z "$BS_HITS" ]] \
  && pass "No backslash execSync paths (silent failure risk — bridge SOPS lesson)" \
  || warn "Backslash in execSync detected: $(echo "$BS_HITS" | head -3)"

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 7 — Config Drift
# ═══════════════════════════════════════════════════════════════════════════════
section "Config Drift"

# Stale port 5679 in source (exclude dist/ build artifacts and docs)
OLD_PORT_HITS=$(grep -rn "5679" --include="*.ts" --include="*.js" --include="*.yaml" --include="*.yml" \
  --exclude-dir=dist --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.planning . \
  2>/dev/null | grep -vE "lessons-learned|HANDOFF|#|//" || true)
[[ -z "$OLD_PORT_HITS" ]] \
  && pass "No stale port 5679 in source files" \
  || warn "Stale port 5679: $(echo "$OLD_PORT_HITS" | wc -l | tr -d ' ') hit(s) — $(echo "$OLD_PORT_HITS" | head -2 | cut -c1-80)"

# DEVOS_ env var names (post-rebrand drift — exclude dist/ artifacts and intentional deprecated aliases)
DEVOS_ENV=$(grep -rn "DEVOS_" --include="*.ts" --include="*.js" \
  --exclude-dir=dist --exclude-dir=node_modules . \
  2>/dev/null | grep -vE "lessons-learned|HANDOFF|deprecated alias|// deprecated" || true)
[[ -z "$DEVOS_ENV" ]] \
  && pass "No stale DEVOS_ env var references in source" \
  || fail "Stale DEVOS_ references: $(echo "$DEVOS_ENV" | wc -l | tr -d ' ') hit(s) — $(echo "$DEVOS_ENV" | head -2 | cut -c1-80)"

# 'dev-os' string in key source files (not URLs or path strings — Windows folder name is still dev-os; exclude dist/)
DEVOS_NAME=$(grep -rn "dev-os" --include="*.ts" --include="*.js" \
  --exclude-dir=dist --exclude-dir=node_modules \
  mcp-local-model/src/ quality-server/server.ts windows-claude-bridge/src/ 2>/dev/null \
  | grep -vE "dev-os\.dev|windows-devos|projects.dev-os|projects\\\\\\\\dev-os" || true)
[[ -z "$DEVOS_NAME" ]] \
  && pass "No stale 'dev-os' name in source files" \
  || warn "Stale 'dev-os' name refs: $(echo "$DEVOS_NAME" | head -3 | cut -c1-80)"

# Lesson number duplicates (use -oE for Mac grep compatibility — no -P needed)
LESSON_NUMS=$(grep -oE '## \[[0-9]+\]' patterns/lessons-learned.md 2>/dev/null | grep -oE '[0-9]+' | sort -n || true)
HIGHEST=$(echo "$LESSON_NUMS" | tail -1)
DUPE_LESSONS=$(echo "$LESSON_NUMS" | uniq -d || true)
[[ -z "$DUPE_LESSONS" ]] \
  && pass "Lesson numbers: no duplicates (highest: ${HIGHEST:-?})" \
  || fail "Duplicate lesson numbers found: $DUPE_LESSONS"

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN 8 — Post-Op: Rebrand Integrity
# ═══════════════════════════════════════════════════════════════════════════════
section "Post-Op: Rebrand Integrity"

# ChromaDB bridge collection name (hermos-bridge not devos-bridge)
BRIDGE_COL=$(echo "${COLLECTIONS:-[]}" | python3 -c "
import sys,json
cols=json.load(sys.stdin)
old=[c['name'] for c in cols if 'devos' in c.get('name','').lower() or 'dev_os' in c.get('name','').lower()]
print(old)" 2>/dev/null || echo "[]")
[[ "$BRIDGE_COL" == "[]" ]] \
  && pass "ChromaDB: no stale devos/dev_os collection names" \
  || fail "ChromaDB: old-named collections: $BRIDGE_COL"

# X-Hermos-Auth (not X-DevOS-Auth) in source (exclude dist/ artifacts)
OLD_HEADER=$(grep -rn "X-DevOS-Auth" --include="*.ts" --include="*.js" \
  --exclude-dir=dist --exclude-dir=node_modules . \
  2>/dev/null | grep -v "lessons-learned\|HANDOFF" || true)
[[ -z "$OLD_HEADER" ]] \
  && pass "No stale X-DevOS-Auth header in source" \
  || fail "Stale X-DevOS-Auth found: $(echo "$OLD_HEADER" | head -2 | cut -c1-80)"

# HERMOS_PATH not DEV_OS_PATH in stop-index script
if [[ -f ~/.claude/stop-index-files.js ]] 2>/dev/null; then
  OLD_PATH_VAR=$(grep "DEV_OS_PATH" ~/.claude/stop-index-files.js 2>/dev/null || true)
  [[ -z "$OLD_PATH_VAR" ]] \
    && pass "stop-index-files.js: uses HERMOS_PATH (not DEV_OS_PATH)" \
    || fail "stop-index-files.js: still references DEV_OS_PATH"
else
  skip "stop-index-files.js not found"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLU}Hermos System Audit  ${DIM}$TIMESTAMP${NC}"
echo -e "  ${GRN}PASS${NC} $PASS_COUNT   ${YEL}WARN${NC} $WARN_COUNT   ${RED}FAIL${NC} $FAIL_COUNT   ${DIM}SKIP${NC} $SKIP_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo -e "${RED}AUDIT FAILED — $FAIL_COUNT check(s) require immediate attention${NC}"
  exit 1
elif [[ "$WARN_COUNT" -gt 0 ]]; then
  echo -e "${YEL}AUDIT PASSED WITH WARNINGS — $WARN_COUNT item(s) to review${NC}"
  exit 2
else
  echo -e "${GRN}AUDIT CLEAN — all $PASS_COUNT checks passed${NC}"
  exit 0
fi

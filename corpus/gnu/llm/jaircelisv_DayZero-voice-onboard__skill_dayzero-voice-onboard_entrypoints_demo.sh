#!/usr/bin/env bash
# DayZero · live demo wrapper · single-command flow for stage demos
# Shows: 1) skill install from registry  2) session reserve  3) phone call wait
#        4) YAML materialization  5) downstream agent createOrder fanout
set -euo pipefail

SKILL="jaircelisv/dayzero-voice-onboard"
BASE="${DAYZERO_API_BASE:-https://dayzero-onboard-7054-325356381078.herokuapp.com}"
SKILL_DIR="${SKILL_DIR:-/Users/jaircelisv/Projects/godat/TherapyFlow/0.Core/Acquisition/hackatones/Ship to Prod/DayZero/skill/dayzero-voice-onboard}"

# colors
G='\033[0;32m'; B='\033[1;34m'; Y='\033[1;33m'; M='\033[1;35m'; D='\033[2m'; C='\033[1;36m'; N='\033[0m'

step()  { echo ""; echo -e "${B}━━━ $1 ━━━${N}"; }
what()  { echo -e "${C}  → $1${N}"; sleep 0.5; }
ok()    { echo -e "  ${G}✓${N} $1"; }
note()  { echo -e "  ${Y}»${N} $1"; }
quiet() { echo -e "  ${D}$1${N}"; }

clear
echo ""
echo -e "${M}╔════════════════════════════════════════════════╗${N}"
echo -e "${M}║         DayZero · Voice Agent Onboarder        ║${N}"
echo -e "${M}║              Tokens& 2026 · live demo          ║${N}"
echo -e "${M}╚════════════════════════════════════════════════╝${N}"
sleep 1

# ─────────────────────────────────────────────────────────
step "1 / 5 · Install the skill from the Shipables registry"
what "Downloads the published DayZero skill from codeables.dev into this workspace."

quiet "$ shipables install ${SKILL}"
echo ""
shipables install "$SKILL" --all --yes 2>&1 | grep -E "Installed|✓|installed|Already" | head -5 || {
  ok "Skill already present in this workspace"
}

# ─────────────────────────────────────────────────────────
step "2 / 5 · Reserve an onboarding session in Redis (TTL 1h)"
what "Asks the backend for a unique session ID linked to this install."

quiet "$ curl -X POST ${BASE}/api/sessions/reserve"
RESP=$(curl -fsS -X POST "${BASE}/api/sessions/reserve" \
  -H "content-type: application/json" \
  -d '{"devId":"live-demo"}')
SID=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['sessionId'])")
NUM=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['onboarderNumber'])")
ok "Session reserved: ${G}${SID}${N}"

# ─────────────────────────────────────────────────────────
echo ""
echo -e "${Y}┌────────────────────────────────────────────────┐${N}"
echo -e "${Y}│                                                │${N}"
printf "${Y}│   📞 CALL NOW:   ${G}%-29s${Y}│${N}\n" "$NUM"
echo -e "${Y}│                                                │${N}"
echo -e "${Y}└────────────────────────────────────────────────┘${N}"
echo ""
note "Pick up your phone and call the number above."
note "Describe your business in 60–90 seconds."
note "Hang up when DayZero says 'Perfect, your agent will be live'."
echo ""
echo -e "${C}  ⏸  When you've hung up, press ${G}ENTER${C} to continue.${N}"
echo ""
read -r _ < /dev/tty

# ─────────────────────────────────────────────────────────
step "3 / 5 · Process the transcript with GPT-4o-mini"
what "Vapi sent the transcript to our backend; GPT-4o-mini converts it into schema-conformant YAML."

bash "$SKILL_DIR/entrypoints/materializer.sh" --latest

# ─────────────────────────────────────────────────────────
step "4 / 5 · Generated agent.yaml"
what "The full voice-agent config — language, voice, system prompt, tools, payment rules — generated from your call."
echo ""
cat dayzero/agent.yaml
echo ""

AGENT_NAME=$(grep -E '^[[:space:]]+name:' dayzero/agent.yaml | head -1 | sed 's/.*name:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]')
ok "Agent name detected: ${G}${AGENT_NAME}${N}"

# ─────────────────────────────────────────────────────────
step "5 / 5 · Test the downstream agent (sample order)"
what "Simulates a customer (Carmen) ordering 24 empanadas. The agent decides to charge a 30% deposit and notify the owner."
echo ""
echo -e "  ${C}⏸  Press ${G}ENTER${C} to fire the sample order (Stripe + Telegram).${N}"
echo -e "  ${C}   Press Ctrl+C to skip.${N}"
echo ""
read -r _ < /dev/tty

echo -e "  ${D}Sample customer call: \"Hola, soy Carmen. Quiero 24 empanadas para el domingo.\"${N}"
echo -e "  ${D}Agent decision: create_order with 30% deposit · notify owner via Telegram${N}"
echo ""
quiet "$ curl -X POST ${BASE}/api/agent/${AGENT_NAME}/createOrder"
ORDER_RESP=$(curl -fsS -X POST "${BASE}/api/agent/${AGENT_NAME}/createOrder" \
  -H "content-type: application/json" \
  -d '{
    "product": "empanadas",
    "quantity": 24,
    "customerName": "Carmen",
    "customerPhone": "+57301234567",
    "scheduledAt": "2026-04-27 15:00",
    "depositCents": 900,
    "currency": "usd"
  }')

PLINK=$(echo "$ORDER_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['paymentLink'])")
TGID=$(echo "$ORDER_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['telegramMessageId'])")
ORDID=$(echo "$ORDER_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['orderId'])")

echo ""
ok "Order:                ${G}${ORDID}${N}"
ok "Stripe payment link:  ${G}${PLINK}${N}"
ok "Telegram message:     ${G}${TGID}${N}  (check the owner's phone)"

echo ""
echo -e "${B}━━━ cited.md audit entry ━━━${N}"
what "Every action is signed with timestamp, sources, and reasoning — Senso's Context Engineering format."
echo ""
cat dayzero/cited.md
echo ""

# ─────────────────────────────────────────────────────────
echo ""
echo -e "${G}╔════════════════════════════════════════════════╗${N}"
echo -e "${G}║                                                ║${N}"
echo -e "${G}║   ✓  Voice in. Real money out.                 ║${N}"
echo -e "${G}║   ✓  YAML generated by GPT-4o-mini.            ║${N}"
echo -e "${G}║   ✓  Stripe link real (test mode).             ║${N}"
echo -e "${G}║   ✓  Telegram notification real.               ║${N}"
echo -e "${G}║   ✓  Every action signed in cited.md.          ║${N}"
echo -e "${G}║                                                ║${N}"
echo -e "${G}║       DayZero · Tokens& 2026                   ║${N}"
echo -e "${G}║                                                ║${N}"
echo -e "${G}╚════════════════════════════════════════════════╝${N}"
echo ""

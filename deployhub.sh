#!/bin/bash
# ============================================================
#  DeployHub — a menu-driven deploy & process manager
#  https://github.com/YOURNAME/deployhub
#  MIT License
#
#  WHAT IT DOES
#   • Turns a folder of plain deploy scripts into an interactive menu.
#   • Every *.sh in SCRIPTS_DIR becomes a menu entry automatically.
#   • Each entry's APP_DIR / DEST_DIR / PM2 name+action are read
#     (grepped) FROM the script itself — the script is the single
#     source of truth. "Deploy" simply runs that script.
#   • Services you haven't written a script for yet appear in a
#     "no script" section with a "Create deploy script" action that
#     scaffolds a starter script; once created they auto-promote to
#     fully script-driven on the next menu refresh.
#
#  REQUIREMENTS: bash 4+, pm2 (optional per-service), git, and
#  whatever each of your own scripts needs (node/npm, go, etc.).
#  See README.md for full setup.
# ============================================================
set -uo pipefail

# ---------- CONFIG (edit these two) --------------------------
SCRIPTS_DIR="${DEPLOYHUB_SCRIPTS_DIR:-$HOME/deploy-scripts}"
EDITOR="${EDITOR:-nano}"
# ------------------------------------------------------------

C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_BOLD=$'\e[1m'
C_GRN=$'\e[32m'; C_YEL=$'\e[33m'; C_CYN=$'\e[36m'; C_RED=$'\e[31m'; C_BLU=$'\e[34m'; C_MAG=$'\e[35m'

mkdir -p "$SCRIPTS_DIR" 2>/dev/null || true

# ============================================================
#  SCRIPT-LESS SERVICES (optional static registry)
#  Declare here any service that does NOT yet have a deploy
#  script but that you still want to see in the menu (so you can
#  edit its .env / view logs / scaffold a script for it).
#
#  FORMAT (pipe-separated):
#    scriptFileName | Display Name | kind | APP_DIR | PM2_NAME
#  kind: generic | node | go   (only affects the scaffold template)
#  Use "-" for PM2_NAME if the service is not managed by pm2.
#
#  Delete these examples and add your own, or leave empty: ()
# ============================================================
SCRIPTLESS=(
  "worker.sh|background-worker (example)|node|/srv/apps/worker|worker"
  "engine.sh|engine (Go, example)|go|/srv/apps/engine|engine"
)

pause() { echo; read -rp "${C_DIM}Press Enter...${C_RESET}"; }
confirm() { read -rp "${C_YEL}$1 [y/N]: ${C_RESET}" a; [[ "$a" =~ ^[Yy]$ ]]; }

# Read a `VAR=value` assignment out of a script.
script_var() {   # <file> <VARNAME>
  grep -m1 -E "^\s*$2=" "$1" 2>/dev/null | head -1 | sed -E "s/^[^=]*=//; s/^[\"']//; s/[\"']\s*$//"
}

# Read the pm2 action + app name out of a script (pm2 restart|reload NAME).
script_pm2() {   # -> "action name"
  grep -m1 -E "pm2 (restart|reload) " "$1" 2>/dev/null \
    | sed -E 's/.*pm2 (restart|reload) ([^ ]+).*/\1 \2/'
}

# Build a badge string by grepping the script for common patterns.
# Extend this freely — add your own greps for your own conventions.
script_badges() {   # <file>
  local f="$1" b=""
  grep -q "rm -rf .next"          "$f" && b+=" ${C_CYN}[clean]${C_RESET}"
  grep -q "npm ci"                "$f" && b+=" ${C_DIM}[npm-ci]${C_RESET}"
  grep -q "npm i -f"              "$f" && b+=" ${C_YEL}[force]${C_RESET}"
  grep -qE "npm i \.\./|link-local" "$f" && b+=" ${C_MAG}[local-pkg]${C_RESET}"
  grep -qE "build-theme|generate-theme" "$f" && b+=" ${C_MAG}[theme]${C_RESET}"
  grep -q "cp -r dist/"           "$f" && b+=" ${C_BLU}[dist]${C_RESET}"
  grep -q "cp -r build/"          "$f" && b+=" ${C_BLU}[build]${C_RESET}"
  grep -q "go build"              "$f" && b+=" ${C_GRN}[go]${C_RESET}"
  grep -q "pm2 reload"            "$f" && b+=" ${C_GRN}[reload]${C_RESET}"
  grep -q "pm2 restart"           "$f" && b+=" ${C_GRN}[restart]${C_RESET}"
  echo "$b"
}

# Optional warning line shown inside a service's menu.
# Extend for your own cross-dependencies.
script_warnings() {  # <file>
  local f="$1"
  grep -qE "npm i \.\./|link-local" "$f" && \
    echo "${C_YEL}! depends on a local package — build that package first if it changed${C_RESET}"
}

pm2_status() {
  local name="$1"
  [[ -z "$name" || "$name" == "-" ]] && { echo "${C_DIM}n/a${C_RESET}"; return; }
  command -v pm2 >/dev/null 2>&1 || { echo "${C_DIM}--${C_RESET}"; return; }
  local pid; pid=$(pm2 pid "$name" 2>/dev/null)
  if [[ -n "$pid" && "$pid" != "0" ]]; then echo "${C_GRN}online${C_RESET}"
  elif pm2 jlist 2>/dev/null | grep -q "\"name\":\"$name\""; then echo "${C_RED}down${C_RESET}"
  else echo "${C_DIM}--${C_RESET}"; fi
}

# ============================================================
#  MENU FOR A SCRIPT-BACKED SERVICE
# ============================================================
script_service_menu() {
  local f="$1"; local base; base=$(basename "$f")
  local dir dest pm2act pm2name
  dir=$(script_var "$f" "APP_DIR")
  dest=$(script_var "$f" "DEST_DIR")
  read -r pm2act pm2name <<<"$(script_pm2 "$f")"
  [[ -z "${pm2name:-}" ]] && pm2name="-"
  while true; do
    clear
    echo "${C_BOLD}${C_BLU}== ${base%.sh} ==${C_RESET}$(script_badges "$f")"
    echo "${C_DIM}script: $f${C_RESET}"
    echo "${C_DIM}dir:    ${dir:-?}${C_RESET}"
    [[ -n "$dest" ]] && echo "${C_DIM}dest:   $dest${C_RESET}"
    echo "${C_DIM}pm2:    $pm2name (${pm2act:-?})   $(pm2_status "$pm2name")${C_RESET}"
    script_warnings "$f"
    echo
    echo "  ${C_GRN}1)${C_RESET} Deploy (run this script)"
    echo "  ${C_GRN}2)${C_RESET} Quick pm2 ${pm2act:-reload} --update-env"
    echo "  ${C_GRN}3)${C_RESET} Edit .env"
    echo "  ${C_GRN}4)${C_RESET} Edit ecosystem.config.js"
    echo "  ${C_GRN}5)${C_RESET} View/edit deploy script"
    echo "  ${C_GRN}6)${C_RESET} Logs (last 40)"
    echo "  ${C_GRN}7)${C_RESET} Live logs"
    echo "  ${C_GRN}8)${C_RESET} cd into project (subshell)"
    echo "  ${C_GRN}9)${C_RESET} restart / stop / start"
    echo "  ${C_DIM}0) back${C_RESET}"
    read -rp "${C_CYN}choose: ${C_RESET}" c
    case "$c" in
      1) confirm "Run ${base}?" && bash "$f"; pause ;;
      2) [[ "$pm2name" != "-" ]] && pm2 "${pm2act:-reload}" "$pm2name" --update-env || echo "no pm2 app"; pause ;;
      3) [[ -n "$dir" ]] && "$EDITOR" "$dir/.env" || echo "no dir" ;;
      4) [[ -f "$dir/ecosystem.config.js" ]] && "$EDITOR" "$dir/ecosystem.config.js" || { echo "no ecosystem file"; pause; } ;;
      5) "$EDITOR" "$f" ;;
      6) [[ "$pm2name" != "-" ]] && pm2 logs "$pm2name" --lines 40 --nostream || echo "no pm2 app"; pause ;;
      7) [[ "$pm2name" != "-" ]] && pm2 logs "$pm2name" || echo "no pm2 app"; pause ;;
      8) echo "${C_YEL}subshell - 'exit' to return${C_RESET}"; (cd "$dir" && exec "$SHELL") ;;
      9) power_menu "$pm2name"; pause ;;
      0) return ;;
    esac
  done
}

# ============================================================
#  MENU FOR A SCRIPT-LESS SERVICE (+ scaffold action)
# ============================================================
scriptless_service_menu() {
  local entry="$1"
  local scriptname disp kind dir pm2name
  scriptname=$(echo "$entry" | cut -d'|' -f1)
  disp=$(echo "$entry" | cut -d'|' -f2)
  kind=$(echo "$entry" | cut -d'|' -f3)
  dir=$(echo "$entry" | cut -d'|' -f4)
  pm2name=$(echo "$entry" | cut -d'|' -f5)
  while true; do
    clear
    echo "${C_BOLD}${C_BLU}== $disp ==${C_RESET}  ${C_YEL}[no script yet]${C_RESET}"
    echo "${C_DIM}dir: $dir${C_RESET}"
    echo "${C_DIM}pm2: $pm2name   $(pm2_status "$pm2name")${C_RESET}"
    echo
    echo "  ${C_GRN}1)${C_RESET} + Create deploy script  (${C_BOLD}$scriptname${C_RESET})"
    echo "  ${C_GRN}2)${C_RESET} Edit .env"
    echo "  ${C_GRN}3)${C_RESET} Edit ecosystem.config.js"
    echo "  ${C_GRN}4)${C_RESET} pm2 restart --update-env"
    echo "  ${C_GRN}5)${C_RESET} Logs (last 40)"
    echo "  ${C_GRN}6)${C_RESET} cd into project (subshell)"
    echo "  ${C_DIM}0) back${C_RESET}"
    read -rp "${C_CYN}choose: ${C_RESET}" c
    case "$c" in
      1) create_script "$scriptname" "$kind" "$dir" "$pm2name"; return ;;
      2) "$EDITOR" "$dir/.env" ;;
      3) [[ -f "$dir/ecosystem.config.js" ]] && "$EDITOR" "$dir/ecosystem.config.js" || { echo "none"; pause; } ;;
      4) [[ "$pm2name" != "-" ]] && pm2 restart "$pm2name" --update-env || echo "no pm2 app"; pause ;;
      5) [[ "$pm2name" != "-" ]] && pm2 logs "$pm2name" --lines 40 --nostream || echo "no pm2 app"; pause ;;
      6) echo "${C_YEL}subshell - 'exit' to return${C_RESET}"; (cd "$dir" && exec "$SHELL") ;;
      0) return ;;
    esac
  done
}

# Scaffold a starter deploy script the user then edits.
create_script() {
  local scriptname="$1" kind="$2" dir="$3" pm2name="$4"
  local out="$SCRIPTS_DIR/$scriptname"
  if [[ -f "$out" ]]; then echo "${C_RED}$out already exists.${C_RESET}"; pause; return; fi
  case "$kind" in
    go)
      cat > "$out" << EOF
#!/bin/bash
set -e
APP_DIR=$dir
echo "Deploying $pm2name..."
cd "\$APP_DIR"
# git stash && git pull origin main       # uncomment if this repo has a remote
echo "go build..."
# EDIT build path/output to match this project:
go build -o bin/app.new ./cmd/... && mv bin/app.new bin/app
echo "pm2 restart..."
pm2 restart $pm2name --update-env
echo "Done."
EOF
      ;;
    node)
      cat > "$out" << EOF
#!/bin/bash
set -e
APP_DIR=$dir
echo "Deploying $pm2name..."
cd "\$APP_DIR"
git stash && git pull origin main
npm install
npm run build            # remove if this project has no build step
pm2 reload $pm2name --update-env
echo "Done."
EOF
      ;;
    *)  # generic
      cat > "$out" << EOF
#!/bin/bash
set -e
APP_DIR=$dir
# DEST_DIR=/var/www/html/your-app     # uncomment for static-site deploys
echo "Deploying..."
cd "\$APP_DIR"
git stash && git pull origin main
# --- build steps here ---
# npm install && npm run build
# --- release steps here ---
# sudo cp -r dist/* "\$DEST_DIR/" && sudo chown -R www-data:www-data "\$DEST_DIR"
# pm2 reload $pm2name --update-env
echo "Done."
EOF
      ;;
  esac
  chmod +x "$out"
  echo "${C_GRN}Created $out${C_RESET}"
  echo "${C_YEL}Opening it so you can fill in the real build/release steps...${C_RESET}"
  pause
  "$EDITOR" "$out"
}

power_menu() {
  local name="$1"; [[ "$name" == "-" ]] && { echo "no pm2 app"; return; }
  echo "  a) restart  b) stop  c) start  d) reload"
  read -rp "action: " p
  case "$p" in a) pm2 restart "$name" --update-env;; b) pm2 stop "$name";; c) pm2 start "$name";; d) pm2 reload "$name" --update-env;; esac
}

global_menu() {
  while true; do
    clear
    echo "${C_BOLD}${C_BLU}== Global / Server ==${C_RESET}"
    echo "  1) pm2 list"
    echo "  2) pm2 save"
    echo "  3) pm2 resurrect"
    echo "  4) nginx -t & reload"
    echo "  5) disk / memory"
    echo "  6) listening ports"
    echo "  0) back"
    read -rp "${C_CYN}choose: ${C_RESET}" c
    case "$c" in
      1) command -v pm2 >/dev/null && pm2 list || echo "pm2 not installed"; pause;;
      2) pm2 save; pause;; 3) pm2 resurrect; pause;;
      4) sudo nginx -t && sudo systemctl reload nginx; pause;;
      5) df -h /; echo; free -h; pause;;
      6) ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null; pause;;
      0) return;;
    esac
  done
}

main_menu() {
  while true; do
    clear
    echo "${C_BOLD}${C_GRN}=================================================${C_RESET}"
    echo "${C_BOLD}${C_GRN}            DeployHub  -  $SCRIPTS_DIR${C_RESET}"
    echo "${C_BOLD}${C_GRN}=================================================${C_RESET}"
    local scripts=(); local s
    for s in "$SCRIPTS_DIR"/*.sh; do [[ -e "$s" ]] && scripts+=("$s"); done
    local pending=(); local e sn
    for e in "${SCRIPTLESS[@]:-}"; do
      [[ -z "$e" ]] && continue
      sn=$(echo "$e" | cut -d'|' -f1)
      [[ -f "$SCRIPTS_DIR/$sn" ]] || pending+=("$e")
    done
    local i=1; local map=()
    if ((${#scripts[@]})); then
      echo; echo "${C_DIM}  -- Script-backed (deployable) --${C_RESET}"
      for s in "${scripts[@]}"; do
        printf "  ${C_GRN}%2d)${C_RESET} %-30s %s%s\n" "$i" "$(basename "${s%.sh}")" "$(pm2_status "$(script_pm2 "$s" | awk '{print $2}')")" "$(script_badges "$s")"
        map+=("S|$s"); i=$((i+1))
      done
    else
      echo; echo "${C_DIM}  (no scripts in $SCRIPTS_DIR yet)${C_RESET}"
    fi
    if ((${#pending[@]})); then
      echo; echo "${C_DIM}  -- No script yet (create one) --${C_RESET}"
      for e in "${pending[@]}"; do
        printf "  ${C_YEL}%2d)${C_RESET} %-30s %s\n" "$i" "$(echo "$e" | cut -d'|' -f2)" "${C_YEL}[+ add script]${C_RESET}"
        map+=("L|$e"); i=$((i+1))
      done
    fi
    echo
    echo "  ${C_YEL}g)${C_RESET} global/server actions    ${C_YEL}q)${C_RESET} quit"
    read -rp "${C_CYN}select #, g, q: ${C_RESET}" choice
    case "$choice" in
      q|Q) clear; exit 0;;
      g|G) global_menu;;
      ''|*[!0-9]*) ;;
      *)
        if ((choice>=1 && choice<=${#map[@]})); then
          local sel="${map[$((choice-1))]}"
          if [[ "$sel" == S\|* ]]; then script_service_menu "${sel#S|}"
          else scriptless_service_menu "${sel#L|}"; fi
        fi;;
    esac
  done
}

main_menu

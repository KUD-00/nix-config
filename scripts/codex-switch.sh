#!/usr/bin/env bash
set -euo pipefail

# codex-switch.sh -- list & switch codex-switcher accounts via TUI
# Reads from ~/.codex-switcher/accounts.json, writes to ~/.codex/auth.json
# Supports: codex-switch              (interactive list + switch)
#           codex-switch status       (check rate limits for current account)
#           codex-switch status-all   (check rate limits for all accounts)
#           codex-switch best         (find & switch to best available account)
#           codex-switch rotate       (rotate accounts on an interval)
#           codex-switch cooldowns    (show persisted weekly cooldowns)

SWITCHER_DIR="${HOME}/.codex-switcher"
ACCOUNTS_FILE="${SWITCHER_DIR}/accounts.json"
STATE_FILE="${SWITCHER_DIR}/runtime-state.json"
AUTH_FILE="${HOME}/.codex/auth.json"
DEFAULT_ROTATE_SECONDS=300
DEFAULT_ROTATE_HEALTHY_PCT=25

die() { echo "[ERR] $*" >&2; exit 1; }

[[ -f "$ACCOUNTS_FILE" ]] || die "accounts.json not found at $ACCOUNTS_FILE"
command -v jq >/dev/null 2>&1 || die "'jq' is required but not found"
command -v python3 >/dev/null 2>&1 || die "'python3' is required but not found"

# Parse accounts into arrays
mapfile -t NAMES < <(jq -r '.accounts[].name' "$ACCOUNTS_FILE")
mapfile -t PLANS < <(jq -r '.accounts[].plan_type' "$ACCOUNTS_FILE")
mapfile -t LAST_USED < <(jq -r '.accounts[].last_used_at // "never"' "$ACCOUNTS_FILE")
mapfile -t ACCOUNT_IDS < <(jq -r '.accounts[].auth_data.account_id // ""' "$ACCOUNTS_FILE")
mapfile -t ACCOUNT_REFRESH_TOKENS < <(jq -r '.accounts[].auth_data.refresh_token // ""' "$ACCOUNTS_FILE")

[[ ${#NAMES[@]} -eq 0 ]] && die "No accounts found in $ACCOUNTS_FILE"

current_account_id=""
current_refresh_token=""
current_account_index=-1

# ─── colors & symbols ───
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_GREEN="\033[32m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"
C_BG_RED="\033[41m"
C_BG_GREEN="\033[42m"
C_BG_YELLOW="\033[43m"
SYM_ACTIVE="▶"
SYM_AVAIL="●"
SYM_LOW="◆"
SYM_EMPTY="○"

# ─── fetch_status: launch codex, send /status, parse result ───
fetch_status() {
  _fetch_status_impl ""
}

_fetch_status_impl() {
  local outfile="${1:-}"    # if set, write results to file; otherwise stdout
  local fake_home="${2:-}"  # if set, override HOME so codex reads isolated auth
  python3 /dev/stdin "$outfile" "$fake_home" << 'PYEOF'
import pty, os, select, time, re, struct, fcntl, termios, signal, sys

outfile = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ""
fake_home = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""

master, slave = pty.openpty()
winsize = struct.pack('HHHH', 50, 140, 0, 0)
fcntl.ioctl(slave, termios.TIOCSWINSZ, winsize)

pid = os.fork()
if pid == 0:
    os.setsid()
    os.dup2(slave, 0); os.dup2(slave, 1); os.dup2(slave, 2)
    os.close(master); os.close(slave)
    os.environ['TERM'] = 'xterm-256color'
    if fake_home:
        os.environ['HOME'] = fake_home
    os.execvp('codex', ['codex', '--no-alt-screen'])

os.close(slave)
output = b""

def drain():
    global output
    while True:
        r, _, _ = select.select([master], [], [], 0.2)
        if r:
            try: output += os.read(master, 8192)
            except: break
        else: break

def clean(s):
    s = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', s)
    s = re.sub(r'\x1b\][^\x07]*\x07', '', s)
    return re.sub(r'\x1b[^[\x1b]', '', s)

def emit(lines):
    text = '\n'.join(lines)
    if outfile:
        with open(outfile, 'w') as f: f.write(text)
    else:
        print(text, flush=True)

start = time.time()

# Retry /status at increasing intervals until MCP is ready
for attempt_at in [8, 12, 16, 20]:
    while time.time() < start + attempt_at:
        drain()
        time.sleep(0.3)

    output = b""
    os.write(master, b"/status\r")

    check_until = time.time() + 4
    while time.time() < check_until:
        drain()
        decoded = clean(output.decode('utf-8', errors='replace'))
        h5 = re.search(r'5h limit:.*?(\d+)%\s+left', decoded)
        wk = re.search(r'Weekly limit:.*?(\d+)%\s+left', decoded)
        if h5 and wk:
            results = []
            acc = re.search(r'Account:\s+(.+?)(?:\s*[│]|\s*$)', decoded, re.MULTILINE)
            if acc: results.append(f"account={acc.group(1).strip()}")
            results.append(f"h5_pct={h5.group(1)}")
            h5r = re.search(r'5h limit:.*?resets?\s+([^)]+)\)', decoded)
            if h5r: results.append(f"h5_reset={h5r.group(1)}")
            results.append(f"weekly_pct={wk.group(1)}")
            wkr = re.search(r'Weekly limit:.*?resets?\s+([^)]+)\)', decoded)
            if wkr: results.append(f"weekly_reset={wkr.group(1)}")
            elapsed = time.time() - start
            results.append(f"fetch_time={elapsed:.1f}")
            try: os.kill(pid, signal.SIGTERM)
            except: pass
            try: os.waitpid(pid, os.WNOHANG)
            except: pass
            emit(results)
            sys.exit(0)
        time.sleep(0.5)

try: os.kill(pid, signal.SIGTERM)
except: pass
try: os.waitpid(pid, os.WNOHANG)
except: pass
emit(["error=timeout"])
PYEOF
}

write_account_auth() {
  local idx="$1"
  local target="$2"
  jq --argjson idx "$idx" '{
    tokens: {
      id_token:      .accounts[$idx].auth_data.id_token,
      access_token:  .accounts[$idx].auth_data.access_token,
      refresh_token: .accounts[$idx].auth_data.refresh_token,
      account_id:    .accounts[$idx].auth_data.account_id
    },
    last_refresh: .accounts[$idx].last_used_at
  }' "$ACCOUNTS_FILE" > "$target"
  chmod 600 "$target"
}

load_current_auth_context() {
  current_account_id=""
  current_refresh_token=""
  if [[ -f "$AUTH_FILE" ]]; then
    current_account_id=$(jq -r '.tokens.account_id // ""' "$AUTH_FILE")
    current_refresh_token=$(jq -r '.tokens.refresh_token // ""' "$AUTH_FILE")
  fi
}

find_account_index_by_name() {
  local wanted="$1"
  local i
  for i in "${!NAMES[@]}"; do
    if [[ "${NAMES[$i]}" == "$wanted" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
}

find_current_account_index() {
  local i
  if [[ -n "$current_account_id" ]]; then
    for i in "${!ACCOUNT_IDS[@]}"; do
      if [[ "${ACCOUNT_IDS[$i]}" == "$current_account_id" ]]; then
        echo "$i"
        return 0
      fi
    done
  fi

  if [[ -n "$current_refresh_token" ]]; then
    for i in "${!ACCOUNT_REFRESH_TOKENS[@]}"; do
      if [[ "${ACCOUNT_REFRESH_TOKENS[$i]}" == "$current_refresh_token" ]]; then
        echo "$i"
        return 0
      fi
    done
  fi

  echo "-1"
}

refresh_current_account_context() {
  load_current_auth_context
  current_account_index=$(find_current_account_index)
}

# ─── state helpers ───
ensure_state_file() {
  mkdir -p "$SWITCHER_DIR"
  if [[ ! -f "$STATE_FILE" ]]; then
    printf '{\n  "schema_version": 1,\n  "weekly_cooldowns": {},\n  "rotate": {}\n}\n' > "$STATE_FILE"
  fi
}

prune_state_file() {
  ensure_state_file
  local now tmp
  now=$(date +%s)
  tmp=$(mktemp)
  jq --argjson now "$now" '
    .schema_version = 1
    | .weekly_cooldowns = (
        (.weekly_cooldowns // {})
        | with_entries(select((.value.until_epoch // 0) > $now))
      )
    | .rotate = (.rotate // {})
  ' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
}

account_key() {
  local idx="$1"
  local account_id="${ACCOUNT_IDS[$idx]}"
  if [[ -n "$account_id" ]]; then
    printf "id:%s" "$account_id"
  else
    printf "name:%s" "${NAMES[$idx]}"
  fi
}

read_weekly_cooldown_until_epoch() {
  local idx="$1"
  local key
  key=$(account_key "$idx")
  ensure_state_file
  jq -r --arg key "$key" '.weekly_cooldowns[$key].until_epoch // ""' "$STATE_FILE"
}

read_rotate_last_index() {
  ensure_state_file
  jq -r '.rotate.last_index // ""' "$STATE_FILE"
}

format_epoch_local() {
  local epoch="$1"
  python3 /dev/stdin "$epoch" << 'PYEOF'
import datetime, sys

epoch = int(sys.argv[1])
dt = datetime.datetime.fromtimestamp(epoch, datetime.timezone.utc).astimezone()
print(dt.strftime("%Y-%m-%d %H:%M:%S %Z"))
PYEOF
}

parse_reset_to_epoch() {
  local reset_text="$1"
  python3 /dev/stdin "$reset_text" << 'PYEOF'
import datetime as dt
import re
import sys

raw = sys.argv[1].strip()
if not raw:
    sys.exit(1)

now = dt.datetime.now().astimezone()
text = raw.strip()
text_l = text.lower().replace(",", " ").replace(" at ", " ")

rel = re.findall(r'(\d+)\s*(w|wk|wks|week|weeks|d|day|days|h|hr|hrs|hour|hours|m|min|mins|minute|minutes)', text_l)
if rel:
    delta = dt.timedelta()
    for value, unit in rel:
        value_i = int(value)
        if unit.startswith("w"):
            delta += dt.timedelta(weeks=value_i)
        elif unit.startswith("d"):
            delta += dt.timedelta(days=value_i)
        elif unit.startswith("h"):
            delta += dt.timedelta(hours=value_i)
        else:
            delta += dt.timedelta(minutes=value_i)
    print(int((now + delta).timestamp()))
    sys.exit(0)

iso_candidate = text.replace("Z", "+00:00")
try:
    parsed = dt.datetime.fromisoformat(iso_candidate)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=now.tzinfo)
    print(int(parsed.astimezone().timestamp()))
    sys.exit(0)
except ValueError:
    pass

formats = [
    "%Y-%m-%d",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d %H:%M:%S",
    "%b %d",
    "%b %d %H:%M",
    "%b %d %I:%M %p",
    "%b %d %Y",
    "%b %d %Y %H:%M",
    "%b %d, %Y",
    "%b %d, %Y %H:%M",
    "%B %d",
    "%B %d %H:%M",
    "%B %d %I:%M %p",
    "%B %d %Y",
    "%B %d %Y %H:%M",
    "%B %d, %Y",
    "%B %d, %Y %H:%M",
]

for fmt in formats:
    try:
        parsed = dt.datetime.strptime(text, fmt)
    except ValueError:
        continue

    if "%Y" not in fmt:
        parsed = parsed.replace(year=now.year)
        if parsed < now - dt.timedelta(hours=1):
            parsed = parsed.replace(year=now.year + 1)

    parsed = parsed.replace(tzinfo=now.tzinfo)
    print(int(parsed.timestamp()))
    sys.exit(0)

sys.exit(1)
PYEOF
}

set_weekly_cooldown() {
  local idx="$1"
  local until_epoch="$2"
  local reset_text="${3:-}"
  local key now tmp

  if [[ -z "$until_epoch" ]]; then
    return 0
  fi

  now=$(date +%s)
  if (( until_epoch <= now )); then
    clear_weekly_cooldown "$idx"
    return 0
  fi

  key=$(account_key "$idx")
  ensure_state_file
  tmp=$(mktemp)
  jq \
    --arg key "$key" \
    --arg name "${NAMES[$idx]}" \
    --arg plan "${PLANS[$idx]}" \
    --arg reset_text "$reset_text" \
    --argjson until_epoch "$until_epoch" \
    --argjson updated_at_epoch "$now" '
      .weekly_cooldowns = (.weekly_cooldowns // {})
      | .rotate = (.rotate // {})
      | .weekly_cooldowns[$key] = {
          name: $name,
          plan: $plan,
          reset_text: $reset_text,
          until_epoch: $until_epoch,
          updated_at_epoch: $updated_at_epoch
        }
    ' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
}

clear_weekly_cooldown() {
  local idx="$1"
  local key tmp
  key=$(account_key "$idx")
  ensure_state_file
  tmp=$(mktemp)
  jq --arg key "$key" '
    .weekly_cooldowns = ((.weekly_cooldowns // {}) | del(.[$key]))
    | .rotate = (.rotate // {})
  ' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
}

write_rotate_last_index() {
  local idx="$1"
  local now tmp
  ensure_state_file
  now=$(date +%s)
  tmp=$(mktemp)
  jq \
    --argjson idx "$idx" \
    --argjson now "$now" '
      .weekly_cooldowns = (.weekly_cooldowns // {})
      | .rotate = (.rotate // {})
      | .rotate.last_index = $idx
      | .rotate.last_switched_at_epoch = $now
    ' "$STATE_FILE" > "$tmp"
  mv "$tmp" "$STATE_FILE"
}

update_weekly_cooldown_for_account() {
  local idx="$1"
  local weekly_pct="${2:-}"
  local weekly_reset="${3:-}"
  local until_epoch=""

  [[ -z "$weekly_pct" ]] && return 0

  if (( weekly_pct > 0 )); then
    clear_weekly_cooldown "$idx"
    return 0
  fi

  if [[ -n "$weekly_reset" ]]; then
    until_epoch=$(parse_reset_to_epoch "$weekly_reset" 2>/dev/null || true)
  fi

  if [[ -n "$until_epoch" ]]; then
    set_weekly_cooldown "$idx" "$until_epoch" "$weekly_reset"
  fi
}

format_cooldown_note() {
  local idx="$1"
  local until_epoch
  until_epoch=$(read_weekly_cooldown_until_epoch "$idx")
  if [[ -z "$until_epoch" ]]; then
    return 0
  fi

  printf "rotate skips until %s" "$(format_epoch_local "$until_epoch")"
}

# ─── switch_to: write auth.json for account index $1 ───
switch_to() {
  local idx="$1"
  mkdir -p "$(dirname "$AUTH_FILE")"
  write_account_auth "$idx" "$AUTH_FILE"
  write_rotate_last_index "$idx"
  refresh_current_account_context
}

prepare_fake_home_for_account() {
  local idx="$1"
  local tmpdir="$2"
  local real_codex="${HOME}/.codex"
  local fake_home="${tmpdir}/home_${idx}"
  local fake_codex="${fake_home}/.codex"

  mkdir -p "$fake_codex"
  write_account_auth "$idx" "${fake_codex}/auth.json"

  [[ -f "${real_codex}/config.toml" ]] && cp "${real_codex}/config.toml" "${fake_codex}/config.toml"

  for f in internal_storage.json version.json models_cache.json .personality_migration; do
    [[ -e "${real_codex}/${f}" ]] && ln -s "${real_codex}/${f}" "${fake_codex}/${f}" 2>/dev/null || true
  done
  for d in cache log memories rules skills; do
    [[ -d "${real_codex}/${d}" ]] && ln -s "${real_codex}/${d}" "${fake_codex}/${d}" 2>/dev/null || true
  done

  printf "%s" "$fake_home"
}

# ─── show_list: print account table ───
show_list() {
  refresh_current_account_context

  local max_len=0
  local name
  for name in "${NAMES[@]}"; do
    (( ${#name} > max_len )) && max_len=${#name}
  done
  (( max_len < 20 )) && max_len=20
  local box_width=$(( max_len + 26 ))

  printf "╔%${box_width}s╗\n" "" | tr ' ' '═'
  printf "║%$(( (box_width + 24) / 2 ))s%$(( box_width - (box_width + 24) / 2 ))s║\n" "Codex Account Switcher" ""
  printf "╠%${box_width}s╣\n" "" | tr ' ' '═'
  local i
  for i in "${!NAMES[@]}"; do
    local marker="  "
    if (( i == current_account_index )); then
      marker="▶ "
    fi
    local last_date="${LAST_USED[$i]:0:10}"
    printf "║ %s%-2d  %-${max_len}s  %4s  %s ║\n" "$marker" "$i" "${NAMES[$i]}" "${PLANS[$i]}" "$last_date"
  done
  printf "╚%${box_width}s╝\n" "" | tr ' ' '═'
}

# ─── format_bar: render a percentage as a colored bar ───
format_bar() {
  local pct="$1"
  local width="${2:-20}"
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  local color=""

  if (( pct <= 5 )); then
    color="$C_RED"
  elif (( pct <= 25 )); then
    color="$C_YELLOW"
  else
    color="$C_GREEN"
  fi

  local j
  for ((j=0; j<filled; j++)); do bar+="█"; done
  for ((j=0; j<empty; j++)); do bar+="░"; done
  printf "${color}%s %3d%%${C_RESET}" "$bar" "$pct"
}

# ─── status_label: return a colored status word ───
status_label() {
  local pct="$1"
  if (( pct == 0 )); then
    printf "${C_BG_RED}${C_WHITE}${C_BOLD} EXHAUSTED ${C_RESET}"
  elif (( pct <= 5 )); then
    printf "${C_RED}${C_BOLD}CRITICAL${C_RESET}"
  elif (( pct <= 25 )); then
    printf "${C_YELLOW}LOW${C_RESET}"
  elif (( pct <= 75 )); then
    printf "${C_GREEN}OK${C_RESET}"
  else
    printf "${C_GREEN}${C_BOLD}PLENTY${C_RESET}"
  fi
}

# ─── min_pct: return the lower of two percentages (effective availability) ───
min_pct() {
  local a="$1" b="$2"
  if (( a < b )); then echo "$a"; else echo "$b"; fi
}

rotate_healthy_threshold_pct() {
  local pct="${CODEX_SWITCH_ROTATE_HEALTHY_PCT:-$DEFAULT_ROTATE_HEALTHY_PCT}"
  [[ "$pct" =~ ^[0-9]+$ ]] || die "CODEX_SWITCH_ROTATE_HEALTHY_PCT must be an integer percentage"
  (( pct >= 0 && pct <= 100 )) || die "CODEX_SWITCH_ROTATE_HEALTHY_PCT must be between 0 and 100"
  echo "$pct"
}

# ─── extract_result_field: safely read key=value output without tripping set -e ───
extract_result_field() {
  local key="$1"
  local source="${2:-/dev/stdin}"
  awk -v prefix="${key}=" '
    index($0, prefix) == 1 {
      print substr($0, length(prefix) + 1)
      exit
    }
    END { exit 0 }
  ' "$source" 2>/dev/null
}

# ─── cmd_status: check current account status ───
cmd_status() {
  refresh_current_account_context
  ensure_state_file
  prune_state_file

  local target_idx="$current_account_index"
  local current_name="(unknown)"
  local current_plan=""

  if (( target_idx >= 0 )); then
    current_name="${NAMES[$target_idx]}"
    current_plan="${PLANS[$target_idx]}"
  fi

  printf "${C_DIM}Checking rate limits for ${C_RESET}${C_BOLD}%s${C_RESET}${C_DIM}...${C_RESET}\n" "$current_name"
  echo ""

  local result account h5_pct h5_reset weekly_pct weekly_reset fetch_error
  result=$(fetch_status)
  account=$(extract_result_field "account" <<< "$result")
  h5_pct=$(extract_result_field "h5_pct" <<< "$result")
  h5_reset=$(extract_result_field "h5_reset" <<< "$result")
  weekly_pct=$(extract_result_field "weekly_pct" <<< "$result")
  weekly_reset=$(extract_result_field "weekly_reset" <<< "$result")
  fetch_error=$(extract_result_field "error" <<< "$result")

  if [[ -z "${h5_pct:-}" && -z "${weekly_pct:-}" ]]; then
    if [[ -n "${fetch_error:-}" ]]; then
      printf "  Could not fetch rate limit data: %s\n" "$fetch_error"
    else
      echo "  Could not parse rate limit data."
    fi
    return
  fi

  if (( target_idx < 0 )) && [[ -n "$account" ]]; then
    target_idx=$(find_account_index_by_name "$account")
    if (( target_idx >= 0 )); then
      current_name="${NAMES[$target_idx]}"
      current_plan="${PLANS[$target_idx]}"
    fi
  fi

  if (( target_idx >= 0 )); then
    update_weekly_cooldown_for_account "$target_idx" "$weekly_pct" "$weekly_reset"
  fi

  printf "  ${C_BOLD}Account:${C_RESET}  %s" "${account:-$current_name}"
  [[ -n "$current_plan" ]] && printf "  ${C_DIM}(%s)${C_RESET}" "$current_plan"
  echo ""
  echo ""

  if [[ -n "${h5_pct:-}" ]]; then
    printf "  ${C_BOLD}5h limit${C_RESET}     "
    format_bar "$h5_pct"
    printf "  "
    status_label "$h5_pct"
    echo ""
    if [[ -n "${h5_reset:-}" ]]; then
      printf "  ${C_DIM}             resets %s${C_RESET}\n" "$h5_reset"
    fi
  fi

  if [[ -n "${weekly_pct:-}" ]]; then
    printf "  ${C_BOLD}Weekly${C_RESET}       "
    format_bar "$weekly_pct"
    printf "  "
    status_label "$weekly_pct"
    echo ""
    if [[ -n "${weekly_reset:-}" ]]; then
      printf "  ${C_DIM}             resets %s${C_RESET}\n" "$weekly_reset"
    fi
    if (( target_idx >= 0 )); then
      local cooldown_note
      cooldown_note=$(format_cooldown_note "$target_idx")
      if [[ -n "$cooldown_note" ]]; then
        printf "  ${C_DIM}             %s${C_RESET}\n" "$cooldown_note"
      fi
    fi
  fi

  if [[ -n "${h5_pct:-}" && -n "${weekly_pct:-}" ]]; then
    local eff
    eff=$(min_pct "$h5_pct" "$weekly_pct")
    echo ""
    printf "  ${C_BOLD}Effective:${C_RESET}   "
    if (( eff == 0 )); then
      printf "${C_RED}${C_BOLD}Unusable${C_RESET} — both limits must have quota\n"
    elif (( eff <= 5 )); then
      printf "${C_YELLOW}Almost out${C_RESET} — consider switching accounts\n"
    else
      printf "${C_GREEN}Available${C_RESET}\n"
    fi
  fi
  echo ""
}

# ─── cmd_status_all: check all accounts ───
cmd_status_all() {
  refresh_current_account_context
  ensure_state_file
  prune_state_file

  local max_len=0
  local name
  for name in "${NAMES[@]}"; do
    (( ${#name} > max_len )) && max_len=${#name}
  done

  local tmpdir
  tmpdir=$(mktemp -d)
  local pids=()
  local count=${#NAMES[@]}
  local start_time
  start_time=$(date +%s)

  printf "${C_BOLD}Checking rate limits for all %d accounts...${C_RESET}\n" "$count"
  echo ""

  local i
  for i in "${!NAMES[@]}"; do
    printf "  ${C_DIM}Launching $(( i + 1 ))/$count: ${NAMES[$i]}...${C_RESET}\r"
    local fake_home
    fake_home=$(prepare_fake_home_for_account "$i" "$tmpdir")
    local outfile="${tmpdir}/${i}.txt"
    (
      _fetch_status_impl "$outfile" "$fake_home"
    ) &
    pids+=($!)
  done

  printf "\033[2K"
  printf "  ${C_DIM}All %d launched in parallel. Waiting for results...${C_RESET}\n" "$count"

  local bg_pid
  for bg_pid in "${pids[@]}"; do
    wait "$bg_pid" 2>/dev/null || true
  done

  local end_time elapsed
  end_time=$(date +%s)
  elapsed=$(( end_time - start_time ))

  declare -a R_H5_PCT R_H5_RESET R_WEEKLY_PCT R_WEEKLY_RESET R_STATUS R_ERROR R_COOLDOWN_UNTIL
  local ok_count=0 exhausted_count=0 low_count=0 err_count=0
  local best_idx=-1 best_score=-1

  for i in "${!NAMES[@]}"; do
    local outfile="${tmpdir}/${i}.txt"
    local h5="" wr="" h5r="" wkr="" err="" status="error" cooldown_until=""

    if [[ -f "$outfile" ]]; then
      h5=$(extract_result_field "h5_pct" "$outfile")
      wr=$(extract_result_field "weekly_pct" "$outfile")
      h5r=$(extract_result_field "h5_reset" "$outfile")
      wkr=$(extract_result_field "weekly_reset" "$outfile")
      err=$(extract_result_field "error" "$outfile")
    else
      err="no-output"
    fi

    if [[ -n "$wr" ]]; then
      update_weekly_cooldown_for_account "$i" "$wr" "$wkr"
    fi
    cooldown_until=$(read_weekly_cooldown_until_epoch "$i")

    R_H5_PCT[$i]="${h5:-}"
    R_H5_RESET[$i]="${h5r:-}"
    R_WEEKLY_PCT[$i]="${wr:-}"
    R_WEEKLY_RESET[$i]="${wkr:-}"
    R_ERROR[$i]="${err:-}"
    R_COOLDOWN_UNTIL[$i]="${cooldown_until:-}"

    if [[ -n "$h5" && -n "$wr" ]]; then
      local eff
      eff=$(min_pct "$h5" "$wr")
      if (( eff == 0 )); then
        status="exhausted"
        (( exhausted_count += 1 ))
      elif (( eff <= 5 )); then
        status="low"
        (( low_count += 1 ))
      else
        status="ok"
        (( ok_count += 1 ))
      fi

      if (( eff > 0 )) && [[ -z "$cooldown_until" ]]; then
        local score=$(( eff * 10000 + h5 * 100 + wr ))
        if (( score > best_score )); then
          best_score=$score
          best_idx=$i
        fi
      fi
    else
      status="error"
      [[ -z "$err" ]] && err="parse-failed"
      R_ERROR[$i]="$err"
      (( err_count += 1 ))
    fi
    R_STATUS[$i]="$status"
  done

  echo ""
  local line_w=80
  printf "  ${C_BOLD}"
  printf "%-3s %-${max_len}s  %-5s  %-25s  %-25s" "#" "Account" "Plan" "5h Limit" "Weekly Limit"
  printf "${C_RESET}\n"
  printf "  ${C_DIM}"
  printf "%${line_w}s" "" | tr ' ' '─'
  printf "${C_RESET}\n"

  for i in "${!NAMES[@]}"; do
    local marker="  "
    if (( i == current_account_index )); then
      marker="${C_CYAN}${SYM_ACTIVE} ${C_RESET}"
    fi

    printf "  %b%-2d ${C_BOLD}%-${max_len}s${C_RESET}  ${C_DIM}%-5s${C_RESET}  " "$marker" "$i" "${NAMES[$i]}" "${PLANS[$i]}"

    if [[ -n "${R_H5_PCT[$i]}" ]]; then
      format_bar "${R_H5_PCT[$i]}" 15
    else
      printf "${C_DIM}%-20s${C_RESET}" "  ?"
    fi

    printf "  "

    if [[ -n "${R_WEEKLY_PCT[$i]}" ]]; then
      format_bar "${R_WEEKLY_PCT[$i]}" 15
    else
      printf "${C_DIM}%-20s${C_RESET}" "  ?"
    fi

    echo ""

    if [[ -n "${R_H5_RESET[$i]}" || -n "${R_WEEKLY_RESET[$i]}" ]]; then
      printf "  ${C_DIM}   %${max_len}s       " ""
      if [[ -n "${R_H5_RESET[$i]}" ]]; then
        printf "↻ %-18s" "${R_H5_RESET[$i]}"
      else
        printf "%-20s" ""
      fi
      printf "  "
      if [[ -n "${R_WEEKLY_RESET[$i]}" ]]; then
        printf "↻ %-18s" "${R_WEEKLY_RESET[$i]}"
      else
        printf "%-20s" ""
      fi
      printf "${C_RESET}\n"
    elif [[ "${R_STATUS[$i]}" == "error" ]]; then
      printf "  ${C_DIM}   %${max_len}s       ${C_RED}x %s${C_RESET}\n" "" "${R_ERROR[$i]:-unknown-error}"
    fi

    if [[ -n "${R_COOLDOWN_UNTIL[$i]}" ]]; then
      printf "  ${C_DIM}   %${max_len}s       rotate skips until %s${C_RESET}\n" "" "$(format_epoch_local "${R_COOLDOWN_UNTIL[$i]}")"
    fi
  done

  printf "  ${C_DIM}"
  printf "%${line_w}s" "" | tr ' ' '─'
  printf "${C_RESET}\n"

  printf "  ${C_BOLD}Summary:${C_RESET}  "
  if (( ok_count > 0 )); then
    printf "${C_GREEN}${C_BOLD}%d available${C_RESET}" "$ok_count"
  fi
  if (( low_count > 0 )); then
    (( ok_count > 0 )) && printf "  ${C_DIM}│${C_RESET}  "
    printf "${C_YELLOW}%d low${C_RESET}" "$low_count"
  fi
  if (( exhausted_count > 0 )); then
    (( ok_count + low_count > 0 )) && printf "  ${C_DIM}│${C_RESET}  "
    printf "${C_RED}%d exhausted${C_RESET}" "$exhausted_count"
  fi
  if (( err_count > 0 )); then
    (( ok_count + low_count + exhausted_count > 0 )) && printf "  ${C_DIM}│${C_RESET}  "
    printf "${C_DIM}%d error${C_RESET}" "$err_count"
  fi
  printf "  ${C_DIM}(%ds)${C_RESET}" "$elapsed"
  echo ""

  if (( best_idx >= 0 )); then
    local is_current=""
    if (( best_idx == current_account_index )); then
      is_current=" (current)"
    fi
    printf "  ${C_BOLD}Best:${C_RESET}      ${C_GREEN}${C_BOLD}%s${C_RESET}${C_DIM}%s${C_RESET}" "${NAMES[$best_idx]}" "$is_current"
    printf "  ${C_DIM}— 5h: %s%% │ weekly: %s%%${C_RESET}\n" "${R_H5_PCT[$best_idx]}" "${R_WEEKLY_PCT[$best_idx]}"

    if (( best_idx != current_account_index )); then
      printf "  ${C_BOLD}Hint:${C_RESET}      ${C_CYAN}codex-switch${C_RESET} then select ${C_BOLD}%d${C_RESET}, or: ${C_CYAN}codex-switch best${C_RESET}\n" "$best_idx"
    fi
  elif (( ok_count + low_count > 0 )); then
    printf "  ${C_YELLOW}No switch-worthy account found above zero effective quota.${C_RESET}\n"
  elif (( exhausted_count > 0 )); then
    printf "  ${C_RED}${C_BOLD}All accounts exhausted!${C_RESET} Wait for limits to reset.\n"
  else
    printf "  ${C_DIM}No account status could be fetched.${C_RESET}\n"
  fi

  echo ""
  rm -rf "$tmpdir"
}

# ─── cmd_best: find best account and optionally switch ───
cmd_best() {
  refresh_current_account_context
  ensure_state_file
  prune_state_file

  local auto_switch="${1:-}"
  printf "${C_BOLD}Finding best available account...${C_RESET}\n\n"

  local tmpdir
  tmpdir=$(mktemp -d)
  local pids=()
  local count=${#NAMES[@]}
  local i

  for i in "${!NAMES[@]}"; do
    printf "  ${C_DIM}Launching $(( i + 1 ))/$count...${C_RESET}\r"
    local fake_home
    fake_home=$(prepare_fake_home_for_account "$i" "$tmpdir")
    local outfile="${tmpdir}/${i}.txt"
    (
      _fetch_status_impl "$outfile" "$fake_home"
    ) &
    pids+=($!)
  done

  printf "\033[2K"
  printf "  ${C_DIM}Waiting for results...${C_RESET}\n"

  local bg_pid
  for bg_pid in "${pids[@]}"; do
    wait "$bg_pid" 2>/dev/null || true
  done

  local best_idx=-1 best_score=-1 best_h5=0 best_wr=0 success_count=0
  for i in "${!NAMES[@]}"; do
    local outfile="${tmpdir}/${i}.txt"
    if [[ -f "$outfile" ]]; then
      local h5 wr wkr eff score cooldown_until
      h5=$(extract_result_field "h5_pct" "$outfile")
      wr=$(extract_result_field "weekly_pct" "$outfile")
      wkr=$(extract_result_field "weekly_reset" "$outfile")
      if [[ -n "$wr" ]]; then
        update_weekly_cooldown_for_account "$i" "$wr" "$wkr"
      fi
      cooldown_until=$(read_weekly_cooldown_until_epoch "$i")

      if [[ -n "$h5" && -n "$wr" ]]; then
        (( success_count += 1 ))
        eff=$(min_pct "$h5" "$wr")
        if (( eff == 0 )) || [[ -n "$cooldown_until" ]]; then
          continue
        fi
        score=$(( eff * 10000 + h5 * 100 + wr ))
        if (( score > best_score )); then
          best_score=$score
          best_idx=$i
          best_h5=$h5
          best_wr=$wr
        fi
      fi
    fi
  done

  rm -rf "$tmpdir"

  if (( best_idx < 0 )); then
    if (( success_count == 0 )); then
      printf "\n  ${C_DIM}No account status could be fetched.${C_RESET}\n\n"
    else
      printf "\n  ${C_RED}${C_BOLD}No account is currently switchable.${C_RESET}\n"
      printf "  ${C_DIM}They are either exhausted or on weekly cooldown.${C_RESET}\n\n"
    fi
    return 1
  fi

  if (( best_idx == current_account_index )); then
    printf "\n  ${C_GREEN}Already on best account: ${C_BOLD}%s${C_RESET}" "${NAMES[$best_idx]}"
    printf "  ${C_DIM}(5h: %d%% │ weekly: %d%%)${C_RESET}\n\n" "$best_h5" "$best_wr"
    return 0
  fi

  printf "\n  ${C_BOLD}Best account:${C_RESET} ${C_GREEN}${C_BOLD}%s${C_RESET}" "${NAMES[$best_idx]}"
  printf "  ${C_DIM}(5h: %d%% │ weekly: %d%%)${C_RESET}\n" "$best_h5" "$best_wr"

  if [[ "$auto_switch" == "--yes" || "$auto_switch" == "-y" ]]; then
    switch_to "$best_idx"
    printf "  ${C_GREEN}[OK]${C_RESET} Switched to: ${C_BOLD}%s${C_RESET}\n\n" "${NAMES[$best_idx]}"
  else
    read -r -p "  Switch to ${NAMES[$best_idx]}? [Y/n] " confirm
    if [[ -z "$confirm" || "$confirm" == "y" || "$confirm" == "Y" ]]; then
      switch_to "$best_idx"
      printf "  ${C_GREEN}[OK]${C_RESET} Switched to: ${C_BOLD}%s${C_RESET}\n\n" "${NAMES[$best_idx]}"
    else
      echo "  Cancelled."
    fi
  fi
}

rotation_start_index() {
  refresh_current_account_context
  ensure_state_file
  prune_state_file

  local start_idx="$current_account_index"
  if (( start_idx < 0 )); then
    local last_idx
    last_idx=$(read_rotate_last_index)
    if [[ "$last_idx" =~ ^[0-9]+$ ]] && (( last_idx < ${#NAMES[@]} )); then
      start_idx="$last_idx"
    fi
  fi

  if (( start_idx < 0 )); then
    start_idx=-1
  fi

  echo "$start_idx"
}

cmd_rotate_once() {
  refresh_current_account_context
  ensure_state_file
  prune_state_file

  local healthy_threshold
  healthy_threshold=$(rotate_healthy_threshold_pct)

  local tmpdir
  tmpdir=$(mktemp -d)
  local pids=()
  local count=${#NAMES[@]}
  local start_idx
  start_idx=$(rotation_start_index)

  local i
  for i in "${!NAMES[@]}"; do
    printf "  ${C_DIM}Checking $(( i + 1 ))/$count: ${NAMES[$i]}...${C_RESET}\r"
    local fake_home
    fake_home=$(prepare_fake_home_for_account "$i" "$tmpdir")
    local outfile="${tmpdir}/${i}.txt"
    (
      _fetch_status_impl "$outfile" "$fake_home"
    ) &
    pids+=($!)
  done

  printf "\033[2K"
  printf "  ${C_DIM}Waiting for account health data...${C_RESET}\n"

  local bg_pid
  for bg_pid in "${pids[@]}"; do
    wait "$bg_pid" 2>/dev/null || true
  done

  declare -a R_H5_PCT R_WEEKLY_PCT R_COOLDOWN_UNTIL R_EFF_PCT R_ERROR
  local current_eff=-1
  local current_h5=""
  local current_wr=""
  local current_cooldown=""
  local current_fetch_ok=0

  for i in "${!NAMES[@]}"; do
    local outfile="${tmpdir}/${i}.txt"
    local h5="" wr="" wkr="" err="" eff="" cooldown_until=""

    if [[ -f "$outfile" ]]; then
      h5=$(extract_result_field "h5_pct" "$outfile")
      wr=$(extract_result_field "weekly_pct" "$outfile")
      wkr=$(extract_result_field "weekly_reset" "$outfile")
      err=$(extract_result_field "error" "$outfile")
    else
      err="no-output"
    fi

    if [[ -n "$wr" ]]; then
      update_weekly_cooldown_for_account "$i" "$wr" "$wkr"
    fi
    cooldown_until=$(read_weekly_cooldown_until_epoch "$i")

    if [[ -n "$h5" && -n "$wr" ]]; then
      eff=$(min_pct "$h5" "$wr")
    fi

    R_H5_PCT[$i]="$h5"
    R_WEEKLY_PCT[$i]="$wr"
    R_COOLDOWN_UNTIL[$i]="$cooldown_until"
    R_EFF_PCT[$i]="$eff"
    R_ERROR[$i]="$err"

    if (( i == current_account_index )) && [[ -n "$h5" && -n "$wr" ]]; then
      current_fetch_ok=1
      current_h5="$h5"
      current_wr="$wr"
      current_eff="$eff"
      current_cooldown="$cooldown_until"
    fi
  done

  if (( current_account_index >= 0 && current_fetch_ok == 1 )) && [[ -z "$current_cooldown" ]] && (( current_eff > healthy_threshold )); then
    write_rotate_last_index "$current_account_index"
    printf "  ${C_GREEN}Current account is still healthy.${C_RESET} "
    printf "${C_DIM}(effective: %s%% │ 5h: %s%% │ weekly: %s%% │ threshold: %s%%)${C_RESET}\n" \
      "$current_eff" "$current_h5" "$current_wr" "$healthy_threshold"
    rm -rf "$tmpdir"
    return 0
  fi

  local next_idx=-1
  local next_reason=""
  local offset idx eff cooldown_until

  for (( offset=1; offset<=count; offset++ )); do
    idx=$(( (start_idx + offset + count) % count ))
    [[ -n "${R_ERROR[$idx]:-}" ]] && [[ -z "${R_H5_PCT[$idx]:-}" ]] && continue
    cooldown_until="${R_COOLDOWN_UNTIL[$idx]:-}"
    eff="${R_EFF_PCT[$idx]:-}"
    [[ -n "$cooldown_until" ]] && continue
    [[ -z "$eff" ]] && continue

    if (( eff > healthy_threshold && eff > current_eff )); then
      next_idx="$idx"
      next_reason="healthy"
      break
    fi
  done

  if (( next_idx < 0 )); then
    for (( offset=1; offset<=count; offset++ )); do
      idx=$(( (start_idx + offset + count) % count ))
      [[ -n "${R_ERROR[$idx]:-}" ]] && [[ -z "${R_H5_PCT[$idx]:-}" ]] && continue
      cooldown_until="${R_COOLDOWN_UNTIL[$idx]:-}"
      eff="${R_EFF_PCT[$idx]:-}"
      [[ -n "$cooldown_until" ]] && continue
      [[ -z "$eff" ]] && continue

      if (( eff > current_eff )); then
        next_idx="$idx"
        next_reason="better"
        break
      fi
    done
  fi

  rm -rf "$tmpdir"

  if (( next_idx < 0 )); then
    if (( current_account_index >= 0 && current_fetch_ok == 1 )) && [[ -z "$current_cooldown" ]] && (( current_eff > 0 )); then
      write_rotate_last_index "$current_account_index"
      printf "  ${C_YELLOW}No better rotation target found; staying on current account.${C_RESET} "
      printf "${C_DIM}(effective: %s%% │ 5h: %s%% │ weekly: %s%%)${C_RESET}\n" \
        "$current_eff" "$current_h5" "$current_wr"
      return 0
    fi

    printf "  ${C_RED}${C_BOLD}No eligible account to rotate to.${C_RESET}\n"
    printf "  ${C_DIM}All accounts are either on weekly cooldown, exhausted, or not healthier than the current one.${C_RESET}\n"
    return 0
  fi

  if (( next_idx == current_account_index )); then
    write_rotate_last_index "$next_idx"
    printf "  ${C_YELLOW}Current account remains the best rotation target:${C_RESET} ${C_BOLD}%s${C_RESET}\n" "${NAMES[$next_idx]}"
    return 0
  fi

  switch_to "$next_idx"
  printf "  ${C_GREEN}[OK]${C_RESET} Rotated to: ${C_BOLD}%s${C_RESET}" "${NAMES[$next_idx]}"
  printf "  ${C_DIM}(effective: %s%% │ 5h: %s%% │ weekly: %s%% │ reason: %s)${C_RESET}\n" \
    "${R_EFF_PCT[$next_idx]}" "${R_H5_PCT[$next_idx]}" "${R_WEEKLY_PCT[$next_idx]}" "$next_reason"
}

cmd_rotate() {
  local once=0
  local interval="$DEFAULT_ROTATE_SECONDS"

  while (($#)); do
    case "$1" in
      --once)
        once=1
        ;;
      --interval)
        shift || die "Missing value for --interval"
        interval="${1:-}"
        ;;
      *)
        die "Unknown rotate option: $1"
        ;;
    esac
    shift || true
  done

  [[ "$interval" =~ ^[0-9]+$ ]] || die "rotate interval must be an integer number of seconds"
  (( interval > 0 )) || die "rotate interval must be greater than zero"

  ensure_state_file
  prune_state_file

  while :; do
    refresh_current_account_context
    printf "${C_BOLD}Rotate pass:${C_RESET} ${C_DIM}%s${C_RESET}\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"

    if (( current_account_index >= 0 )); then
      printf "  ${C_DIM}Current:${C_RESET} %s\n" "${NAMES[$current_account_index]}"
    else
      printf "  ${C_DIM}Current:${C_RESET} (unknown)\n"
    fi

    cmd_rotate_once || true
    echo ""

    if (( once == 1 )); then
      break
    fi

    printf "${C_DIM}Sleeping %ds until next rotation...${C_RESET}\n\n" "$interval"
    sleep "$interval"
  done
}

cmd_cooldowns() {
  ensure_state_file
  prune_state_file

  local had_any=0
  while IFS=$'\t' read -r key name plan until_epoch reset_text; do
    had_any=1
    printf "${C_BOLD}%-24s${C_RESET}  ${C_DIM}%-5s${C_RESET}  until %s" "$name" "$plan" "$(format_epoch_local "$until_epoch")"
    if [[ -n "$reset_text" ]]; then
      printf "  ${C_DIM}(raw: %s)${C_RESET}" "$reset_text"
    fi
    echo ""
  done < <(
    jq -r '
      (.weekly_cooldowns // {})
      | to_entries[]
      | [
          .key,
          (.value.name // ""),
          (.value.plan // ""),
          (.value.until_epoch | tostring),
          (.value.reset_text // "")
        ]
      | @tsv
    ' "$STATE_FILE"
  )

  if (( had_any == 0 )); then
    printf "${C_DIM}No active weekly cooldowns recorded.${C_RESET}\n"
  fi
}

refresh_current_account_context

# ─── main ───
case "${1:-}" in
  status)
    cmd_status
    ;;
  status-all)
    cmd_status_all
    ;;
  best)
    shift || true
    cmd_best "${1:-}"
    ;;
  rotate)
    shift || true
    cmd_rotate "$@"
    ;;
  cooldowns)
    cmd_cooldowns
    ;;
  help|--help|-h)
    cat <<EOF
codex-switch -- manage Codex CLI account switching

USAGE
  codex-switch                   Interactive account list & switch
  codex-switch status            Show rate limits for current account
  codex-switch status-all        Show rate limits for ALL accounts (parallel)
  codex-switch best              Find & switch to best available account
  codex-switch best -y           Auto-switch without confirmation
  codex-switch rotate            Rotate forever every 300s
  codex-switch rotate --once     Do one rotation pass
  codex-switch rotate --interval 120
                                 Rotate forever every 120s
  codex-switch cooldowns         Show persisted weekly cooldowns
  codex-switch help              This message

ENV
  CODEX_SWITCH_ROTATE_HEALTHY_PCT
                                 Effective quota threshold for keeping current
                                 account during rotate (default: 25)
EOF
    ;;
  *)
    show_list

    echo ""
    read -r -p "Select account number (or 'q' to quit, 's' for status): " choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
      exit 0
    fi

    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
      cmd_status
      exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 0 || choice >= ${#NAMES[@]} )); then
      die "Invalid selection: $choice"
    fi

    if (( choice == current_account_index )); then
      echo "[*] Already on ${NAMES[$choice]}, nothing to do."
      exit 0
    fi

    switch_to "$choice"
    echo "[OK] Switched to: ${NAMES[$choice]}"
    ;;
esac

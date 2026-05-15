#!/usr/bin/env bash
# Emits the full tmux status-right string in one fork.
# Performance: ~30ms total on macOS, runs every status-interval.

DIM="${TMUX_DIM:-#727072}"
FG="${TMUX_FG:-#fcfcfa}"
CYAN="${TMUX_CYAN:-#78dce8}"
YELLOW="${TMUX_YELLOW:-#ffd866}"
GREEN="${TMUX_GREEN:-#a9dc76}"
RED="${TMUX_RED:-#ff6188}"
ORANGE="${TMUX_ORANGE:-#fc9867}"

sep="#[fg=${DIM}]│"

pick_color() {
  # pick_color value yellow_threshold red_threshold
  awk -v v="$1" -v y="$2" -v r="$3" -v G="$GREEN" -v Y="$YELLOW" -v R="$RED" \
    'BEGIN { if (v+0 >= r) print R; else if (v+0 >= y) print Y; else print G }'
}

# --- CPU% (sum of per-process %CPU normalized by cores) ---
cores=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu | awk -v c="$cores" 'NR>1{s+=$1} END{printf "%.0f", s/c}')
cpu_color=$(pick_color "$cpu" 40 70)

# --- Load (1-min) colored vs cores ---
load=$(sysctl -n vm.loadavg | awk '{print $2}')
load_color="${GREEN}"
awk -v l="$load" -v c="$cores" 'BEGIN { exit !(l/c > 0.7) }' && load_color="${YELLOW}"
awk -v l="$load" -v c="$cores" 'BEGIN { exit !(l/c > 1.2) }' && load_color="${RED}"

# --- Memory used % (Activity Monitor parity: active+wired+compressed) ---
mem=$(vm_stat | awk '
  /page size of/             { ps=$8 }
  /Pages free/               { gsub("[.]",""); free=$3 }
  /Pages active/             { gsub("[.]",""); active=$3 }
  /Pages inactive/           { gsub("[.]",""); inactive=$3 }
  /Pages speculative/        { gsub("[.]",""); spec=$3 }
  /Pages wired down/         { gsub("[.]",""); wired=$4 }
  /Pages occupied by compressor/ { gsub("[.]",""); comp=$5 }
  END {
    used  = active + wired + comp
    total = free + active + inactive + spec + wired + comp
    if (total > 0) printf "%.0f", 100*used/total
  }
')
mem_color=$(pick_color "$mem" 60 80)

# --- Disk usage on / ---
disk=$(df -k / | awk 'NR==2 {gsub("%",""); print $5}')
disk_color=$(pick_color "$disk" 70 85)

# --- Battery ---
batt_pct=""
batt_glyph=""
batt_color="${FG}"
if pmset -g batt 2>/dev/null | grep -q InternalBattery; then
  read batt_pct batt_state < <(pmset -g batt | awk '/InternalBattery/{ for (i=1;i<=NF;i++) if ($i ~ /%/) { gsub("[%;]","",$i); pct=$i; st=$(i+1); gsub(";","",st); print pct, st; exit } }')
  case "$batt_state" in
    charged)      batt_glyph="bat";  batt_color="${GREEN}" ;;
    charging|AC)  batt_glyph="chg";  batt_color="${CYAN}"  ;;
    finishing)    batt_glyph="chg";  batt_color="${CYAN}"  ;;
    discharging)
      batt_glyph="bat"
      if   [ "$batt_pct" -le 20 ]; then batt_color="${RED}"
      elif [ "$batt_pct" -le 50 ]; then batt_color="${ORANGE}"
      elif [ "$batt_pct" -le 80 ]; then batt_color="${YELLOW}"
      else                              batt_color="${GREEN}"
      fi ;;
    *) batt_glyph="bat" ;;
  esac
fi

# --- Date/time ---
date_part=$(date "+%a %d %b")
time_part=$(date "+%H:%M")

# --- Assemble ---
# Plain ASCII labels (font-agnostic). Switch to Nerd Font glyphs if you
# install one (e.g. FiraCode Nerd Font) in ghostty.
out=""
out+=" #[fg=${DIM}]cpu #[fg=${cpu_color}]${cpu}% ${sep}"
out+=" #[fg=${DIM}]ld  #[fg=${load_color}]${load} ${sep}"
out+=" #[fg=${DIM}]mem #[fg=${mem_color}]${mem}% ${sep}"
out+=" #[fg=${DIM}]dsk #[fg=${disk_color}]${disk}% ${sep}"
if [ -n "$batt_pct" ]; then
  out+=" #[fg=${DIM}]${batt_glyph} #[fg=${batt_color}]${batt_pct}% ${sep}"
fi
out+=" #[fg=${DIM}]${date_part} #[fg=${YELLOW}]${time_part} "

printf '%s' "$out"

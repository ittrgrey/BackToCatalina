#!/usr/bin/env zsh
# process-report — list running processes, bucketed by:
#   1. current user vs other users
#   2. windowed (GUI, has Dock/menu-bar presence) vs background
#
# Usage:
#   ./process-report.zsh              # full 4-section report + Ammonia Exclusions
#   ./process-report.zsh -s           # per-user count summary table
#   ./process-report.zsh -a           # only the Ammonia Exclusions section
#   ./process-report.zsh -o FILE      # write report to FILE
#   ./process-report.zsh -u USER      # treat USER as "me" instead of $(whoami)

set -euo pipefail

mode="full"
outfile=""
me="$(whoami)"

while (( $# )); do
  case "$1" in
    -s|--summary)      mode="summary" ;;
    -a|--ammonia-only) mode="ammonia" ;;
    -o|--output)  shift; outfile="${1:?-o requires a path}" ;;
    -u|--user)    shift; me="${1:?-u requires a username}" ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) print -u2 "unknown arg: $1"; exit 2 ;;
  esac
  shift
done

# PIDs of processes that AppKit considers foreground GUI apps.
# `background only is false` = has Dock icon / menu bar (i.e. a real windowed app).
windowed_pids="$(
  osascript -e 'tell application "System Events" to get the unix id of (every process whose background only is false)' 2>/dev/null \
  | tr -d ' ' | tr ',' '|'
)"

render() {
  ps -axo user=,pid=,comm= | awk -v me="$me" -v wpids="$windowed_pids" -v mode="$mode" '
    function print_bins(arr,    n, names, i, j, t, name) {
      n = 0
      for (name in arr) names[++n] = name
      for (i = 2; i <= n; i++) {
        t = names[i]; j = i - 1
        while (j >= 1 && tolower(names[j]) > tolower(t)) { names[j+1] = names[j]; j-- }
        names[j+1] = t
      }
      if (n == 0) { print "  (none)"; return }
      for (i = 1; i <= n; i++) printf "  %s\n", names[i]
    }
    BEGIN {
      n = split(wpids, arr, "|")
      for (i = 1; i <= n; i++) windowed[arr[i]] = 1
    }
    {
      user = $1; pid = $2
      cmd = ""
      for (i = 3; i <= NF; i++) cmd = cmd (i==3?"":" ") $i
      is_win = (pid in windowed) ? "windowed" : "background"
      is_me  = (user == me) ? "me" : "other"
      bucket = is_me "_" is_win
      rows[bucket] = rows[bucket] sprintf("  %-6s  %-22s  %s\n", pid, user, cmd)
      count[bucket]++
      ucount[user "|" is_win]++
      users[user] = 1
      if (is_win == "background") {
        bin = cmd; sub(/.*\//, "", bin)
        if (is_me == "me") me_bg_bin[bin]++
        else                other_bg_bin[bin]++
      }
    }
    END {
      if (mode == "summary") {
        printf "%-22s %12s %12s %8s\n", "USER", "WINDOWED", "BACKGROUND", "TOTAL"
        printf "%-22s %12s %12s %8s\n", "----", "--------", "----------", "-----"
        n = 0
        for (u in users) { order[++n] = u; total[u] = ucount[u "|windowed"] + ucount[u "|background"] }
        for (i = 1; i <= n; i++)
          for (j = i+1; j <= n; j++)
            if (total[order[j]] > total[order[i]]) { t = order[i]; order[i] = order[j]; order[j] = t }
        for (i = 1; i <= n; i++) {
          u = order[i]
          printf "%-22s %12d %12d %8d\n", u, ucount[u "|windowed"]+0, ucount[u "|background"]+0, total[u]
        }
        exit
      }

      if (mode != "ammonia") {
        labels[1] = "MY USER (" me ") — WINDOWED"
        labels[2] = "MY USER (" me ") — BACKGROUND"
        labels[3] = "OTHER USERS — WINDOWED"
        labels[4] = "OTHER USERS — BACKGROUND"
        keys[1] = "me_windowed"; keys[2] = "me_background"
        keys[3] = "other_windowed"; keys[4] = "other_background"
        for (i = 1; i <= 4; i++) {
          printf "==== %s (%d) ====\n", labels[i], count[keys[i]]+0
          if (rows[keys[i]] == "") print "  (none)"
          else printf "%s", rows[keys[i]]
          print ""
        }
      }

      print "==== Ammonia Exclusions ===="
      print ""
      print "-- Owned by me --"
      print_bins(me_bg_bin)
      print ""
      print "-- System processes --"
      print_bins(other_bg_bin)
    }
  '
}

if [[ -n "$outfile" ]]; then
  render > "$outfile"
  print "wrote $(wc -l < "$outfile" | tr -d ' ') lines to $outfile"
else
  render
fi

# process-report

A zsh script for macOS that lists running processes, bucketed by **owner** (your user vs. everyone else) and by **window state** (GUI/windowed vs. background). Also produces an "Ammonia Exclusions" list of unique background-process binary names, suitable for feeding into an exclusion config.

## Requirements

- macOS (relies on `osascript` + `System Events`)
- zsh (the script's shebang is `/usr/bin/env zsh`)
- Standard BSD `ps` and `awk` (both ship with macOS — no `gawk` needed)

On first run, macOS will prompt your terminal application for permission to control **System Events** (Automation). Approve it; otherwise the windowed-process query returns nothing and every process gets classified as background.

## How it works

Two data sources are joined by PID:

1. **All processes** come from `ps -axo user=,pid=,comm=` — every process on the system, with its owning user and command path.
2. **Windowed PIDs** come from an AppleScript one-liner:
   ```
   tell application "System Events" to get the unix id of (every process whose background only is false)
   ```
   In AppKit, `background only is false` means the process has a Dock icon or menu-bar presence — i.e. a real foreground GUI app. This excludes hidden agents, XPC services, and headless helpers, even if they're technically capable of drawing windows.

An `awk` block then:
- Tags each process as `me` vs `other` (by comparing owner against `$(whoami)` or the `-u` override).
- Tags each process as `windowed` vs `background` (by PID lookup against the AppleScript result).
- Builds the four cross-product buckets and the Ammonia Exclusions lists.

For the Ammonia Exclusions section, the binary basename is extracted (`sub(/.*\//, "", bin)`), then deduped and sorted case-insensitively.

## Usage

```
./process-report.zsh [OPTIONS]
```

### Options

| Flag | Long form | Description |
|------|-----------|-------------|
| `-s` | `--summary`      | Print a per-user count table (USER × WINDOWED × BACKGROUND × TOTAL), sorted by total desc. No per-process detail. |
| `-a` | `--ammonia-only` | Print only the Ammonia Exclusions section (skip the four detail sections). |
| `-o FILE` | `--output FILE` | Write the rendered report to `FILE` instead of stdout. Prints a one-line confirmation with the line count. |
| `-u USER` | `--user USER` | Treat `USER` as "me" instead of `$(whoami)`. Useful for inspecting another account's process tree. |
| `-h` | `--help` | Print usage and exit. |

Flags can be combined: e.g. `-a -o ~/exclusions.txt` writes only the Ammonia list to a file.

### Default report layout

With no flags, the output has five sections in this order:

1. `==== MY USER (you) — WINDOWED (N) ====` — your foreground GUI apps. Each row: `PID  USER  COMMAND`.
2. `==== MY USER (you) — BACKGROUND (N) ====` — everything else you own (daemons, helpers, shells, language servers, etc.).
3. `==== OTHER USERS — WINDOWED (N) ====` — windowed processes owned by someone else (rare on a single-user Mac; typically only `loginwindow`-adjacent processes).
4. `==== OTHER USERS — BACKGROUND (N) ====` — system daemons and other-user processes (`root`, `_coreaudiod`, `_locationd`, etc.).
5. `==== Ammonia Exclusions ====` — two subsections (`-- Owned by me --` and `-- System processes --`) listing the unique binary names of all background processes, sorted case-insensitively. No PIDs, no paths, no counts — just exact names, one per line.

## Examples

```zsh
# Full report to terminal
./process-report.zsh

# Just the per-user counts
./process-report.zsh -s

# Just the exclusions list, saved for use elsewhere
./process-report.zsh -a -o ~/exclusions.txt

# Diff your exclusion list before and after installing something
./process-report.zsh -a > /tmp/before.txt
# ... install thing ...
./process-report.zsh -a > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt

# Inspect what root is running, treating root as "me"
./process-report.zsh -u root
```

## Putting it on `$PATH`

The script lives at `~/salt_development/process-report/process-report.zsh`. To call it as just `process-report` from anywhere:

```zsh
ln -s ~/salt_development/process-report/process-report.zsh ~/.local/bin/process-report
```

(`~/.local/bin` is already on your `$PATH`.)

## Caveats

- **AppleScript permission**: if System Events access is denied, every process will be classified as background. If you see zero windowed processes despite having GUI apps open, check **System Settings → Privacy & Security → Automation**.
- **Snapshot, not stream**: results are a single point-in-time view. Short-lived processes (`grep`, `awk` invocations, including the script's own `ps` and `awk`) may or may not appear depending on timing.
- **`comm=` output**: BSD `ps`'s `comm=` field shows the executable path, not the full argv. So you can't distinguish multiple `python3` processes by their script. Switch to `ps -axo user=,pid=,command=` (note: `command`, not `comm`) if you want full argv — but be aware that breaks the awk field-split assumption since argv contains spaces.
- **"Windowed" is AppKit-defined**: an Electron app with all windows closed but still running in the Dock counts as windowed. A `tmux` session in iTerm does not count as its own windowed process — only `iTerm2` itself does.

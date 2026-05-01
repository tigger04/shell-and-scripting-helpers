# Full Code Review: `.qfuncs.sh`

**Date:** 2026-05-01
**Lines:** 1818
**Scope:** Full library audit against CODING.md and shell best practice

---

## Blockers

### B1. `blockchart` calls `set -e` without restoring it (line 987)

`set -e` is called at line 987 inside `blockchart()`. Since this is a sourced library, `set -e` persists into the caller's environment after the function returns. Any script that sources `.qfuncs.sh` and calls `blockchart` will have `set -e` enabled for all subsequent code — even if the script didn't set it.

**Fix:** Remove `set -e` from `blockchart`. The function already uses explicit `|| exit 1` checks. If `set -e` is genuinely needed, save and restore: `local prev_e=...; ... ; restore`.

### B2. `blockchart` uses `exit` instead of `return` (lines 1021-1022)

```bash
[ $bc_metric_unadulterated -le $bc_max ] || exit 1
[ $bc_metric_unadulterated -ge 0 ] || exit 1
```

Since `.qfuncs.sh` is sourced (not executed), `exit 1` kills the calling shell. These should be `return 1`.

### B3. `which` used instead of `command -v` (lines 1636-1645)

```bash
read -r cp < <(which gcp)
read -r ln < <(which gln)
read -r rm < <(which grm)
read -r mv < <(which gmv)
```

`which` is non-standard, may produce unexpected output (aliases, shell built-in messages), and is explicitly prohibited by CODING.md. Use `command -v` instead.

### B4. Contradictory bash version checks (lines 97 vs 1621)

Line 97 checks for bash >= 4:
```bash
if [ "${BASH_VERSINFO:-0}" -lt 4 ]; then
```

Line 1621 checks for bash >= 5:
```bash
if ! [ ${BASH_VERSINFO[0]} -ge 5 ]; then
```

The first check passes for bash 4 and lets execution continue through ~1500 lines of code before the second check kills the shell. Only one check should exist, and it should be at the top. Since the file uses bash 5+ features (associative arrays are bash 4, but `${var,,}` case conversion in some forms and `EPOCHREALTIME` are bash 5), the check should be >= 5.

### B5. `rm -f` used in `clean_up_plain_text` (line 1588)

```bash
rm -f "$REPLY"
```

CODING.md prohibits `rm`; only `trash` is allowed. The exception is short-lived temp files, but `$REPLY` here is the backup file the user might want.

### B6. `oneline` references undefined ANSI variables (lines 1120)

```bash
echo -ne "${biblack}${oneline_line:0:$cols}${ansi_off}\r"
```

`$biblack` and `$ansi_off` are never defined anywhere in this file. The comment at line 12 explains ANSI colours were abandoned in favour of emojis, but this function still uses them. The variables will be empty strings, making the function work but not as intended.

### B7. `blockchart` echo/printf-v behavioural mismatch (lines 1013, 1056-1058)

`bc_empty` is set to the escape `'\U2B1B'`. The `echo -ne` path (stdout) interprets this as a Unicode character. The `printf -v '%s'` path (variable assignment) stores the literal string `\U2B1B`. Callers using `-v VAR` get different content than callers using stdout.

**Fix:** Use the literal Unicode character: `local bc_empty='⬛'`

---

## Smells

### S1. `caller()` shadows the bash built-in (line 908)

Bash has a built-in `caller` command used for debugging (returns line number, subroutine name, and filename). Defining a function named `caller` shadows it. Any script or debugging tool that relies on `builtin caller` will silently get wrong behaviour.

**Fix:** Rename to something like `get_caller` or `parent_cmd`.

### S2. `deprecated()` uses `exit` instead of `return` (line 804)

The default case calls `exit 101`, which kills the sourcing shell. A deprecated function should warn and return, not terminate the entire session.

### S3. `die()` does not declare `rc` as local (line 88)

```bash
rc=$?
```

This leaks `rc` into the caller's scope. Should be `local rc=$?`.

### S4. `confirm_cmd_execute` leaks `rc` into caller scope (line 651)

Same issue: `rc=$?` without `local`.

### S5. Massive code duplication: `ok_pause` and `ok_confirm` (lines 406-584)

These two functions are ~90 lines each and nearly identical. The only differences are: default timeout (0 vs 15), prompt text, and the response handling (any key vs y/N). A single function with a mode parameter would eliminate ~80 lines of duplication.

### S6. `print_dots()` defined inside `ok_pause` and `ok_confirm` (lines 454, 543)

Nested function definitions in bash are not scoped — they pollute the global namespace. `print_dots` is defined identically twice. It should be a standalone function, or at minimum defined only once.

### S7. `format_manpage` exceeds 50 lines (lines 1649-1749)

At 100 lines, this is double the CODING.md limit. The formatting branches (section headers, options, paths, quoted text) could each be helper functions.

### S8. `fullpath` exceeds 50 lines (lines 668-764)

At ~96 lines, also well over the limit. The `..` / `.` normalisation logic could be extracted.

### S9. `azonly` exceeds 50 lines (lines 1236-1332)

The inner `az_sanitize` function adds to the size. The nested function also leaks into the global namespace.

### S10. `process_segment` is a global helper for `azrandomize` (lines 1409-1434)

This is only used by `azrandomize` but is defined at the top level, polluting the namespace. Worse, `azrandomize` calls it via `$(process_segment ...)` — a subshell per word, which contradicts the library's stated goal of avoiding subshells.

### S11. `color_timestamps` has `shift` inside a `while read` loop (line 1211)

```bash
while read -r print_color_line; do
    echo "$print_color_line"
    shift    # <-- shifts positional params, not stdin lines
done
```

`shift` in a read loop does nothing useful — it shifts `$@`, not the input stream. This is likely a leftover from refactoring.

### S12. Dead code: commented-out `sanitize` function (lines 922-934)

13 lines of commented-out code. If it is needed later, it is in git history. If it is not, it is clutter.

### S13. Dead code: commented-out lines in `die`, `qbase` (lines 90-91, 253)

Small instances of commented-out code that should be removed or documented with a TODO.

### S14. `echo -e` used for user-facing output (multiple locations)

Functions like `warn`, `errortext`, `info`, `highlight`, `ok`, `ticktext` all use `echo -e`. If message text ever contains backslash sequences (e.g. a filename with `\n` in it), `echo -e` will interpret them. `printf '%s\n'` is safer, though the emoji prefix makes accidental interpretation unlikely.

### S15. `qpager` and `qln` use variable-as-command pattern (lines 943, 953)

```bash
"$qpager"
"$qln" "$@"
```

CODING.md prohibits `$cmd` as a command execution pattern. These are technically safe (the values come from `command -v`, not user input), but they match the prohibited pattern. A `case` or `if/else` dispatch would be more explicit.

### S16. `confirm_continue` does not declare `timeout` as local (lines 601, 604)

```bash
timeout=()
timeout=(-t "$t")
```

`timeout` leaks into the caller's scope.

### S17. `hline` function name collides with local variable (lines 256, 270)

The function is named `hline` and uses `${hline:-=}` as a default — this reads a *global* variable also named `hline`. This works (the function doesn't call itself recursively), but it is confusing. The global should have a distinct name like `HLINE_CHAR`.

### S18. `imgstring` function and variable share the same name (lines 67-74)

The function `imgstring()` writes to a global variable also called `imgstring`. This works in bash but is confusing and easy to misuse — calling the function name without `()` returns the variable, not the function result.

### S19. `random_hex` function and local variable share the same name (line 1073)

```bash
local random_hex=$((RANDOM % 16))
```

The local variable shadows the function name within the function body. Not a bug, but confusing to read.

### S20. No ABOUTME comment

CODING.md requires every code file to start with a 2-line ABOUTME comment explaining its purpose. The file has explanatory comments but not in the required format.

### S21. `gsed` used without availability check (line 1591)

`clean_up_plain_text` calls `gsed` directly on the stdin path (line 1591) without checking if it exists. On Linux, `gsed` is not installed by default — `sed` is the GNU version there.

### S22. `free_disk_space_kb` is identical to `free_disk_space_human` (lines 1751-1771)

Both functions have exactly the same implementation (`df -h`). The `_kb` variant should presumably use `df -k` or `df` without `-h`, but it doesn't — it returns human-readable output despite the name.

### S23. `bat()` wrapper may recurse (lines 1217-1225)

The function is named `bat` and uses `command -v bat` to check for the binary. This works correctly because `command -v` checks for external commands first. However, if `bat` is not installed, every call produces a warning — this could be noisy in scripts that call it frequently.

### S24. TODOs without issue references (lines 327, 336)

```bash
#TODO: support STDIN
```

CODING.md flags TODOs without issue references as requiring justification.

---

## Summary

| Category | Count |
|---|---|
| Blockers | 7 |
| Smells | 24 |

The library achieves its stated goal of fast, subshell-free helpers effectively. The main structural issues are: `blockchart`'s `set -e`/`exit` (B1/B2) which can kill calling shells, the `which` usage (B3), the contradictory version checks (B4), and several namespace collisions (S1, S17-S19). The duplication between `ok_pause` and `ok_confirm` (S5) is the most significant maintainability concern.

#!/usr/bin/env bash
#
# Regression test: re-running install-agentic-knowledge.sh on a repo must NOT
# clobber project-custom ignore files.
#   - an existing .gitnexusignore is kept byte-for-byte (same as .cbmignore)
#   - .gitignore gets the "# Local code intelligence artifacts" header only when
#     at least one entry is actually missing (no dangling header), and re-runs
#     are byte-for-byte idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-agentic-knowledge.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BIN_DIR="$TMP_DIR/bin"
mkdir -p "$BIN_DIR" "$TMP_DIR/vault"

# Offline stub: `npm view gitnexus version` → a fixed exact version.
cat > "$BIN_DIR/npm" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "view" ]] && { echo "1.6.8"; exit 0; }
exit 0
STUB
chmod +x "$BIN_DIR/npm"

fail() { echo "FAIL: $*" >&2; exit 1; }

run_installer() {
  PATH="$BIN_DIR:$PATH" SKIP_CMM=1 bash "$INSTALLER" --repo "$1" \
    --vault-root "$TMP_DIR/vault" --skip-initial-run --skip-vector-deps \
    --no-claude --no-codex --no-antigravity >/dev/null 2>&1 \
    || fail "installer exited non-zero for $1"
}

new_repo() {
  local dir="$TMP_DIR/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  echo "$dir"
}

HEADER="# Local code intelligence artifacts"

# --- Case 1: existing custom .gitnexusignore + .gitignore already covering all entries
R1="$(new_repo custom)"
cat > "$R1/.gitnexusignore" <<'IGN'
graphify-out/
semantic-vector-index/
.gitnexus/
scripts/node_modules/
99_archive/
prototypes/**/*.mp4
*.png
*.pdf
IGN
cat > "$R1/.gitignore" <<'IGN'
node_modules/
.gitnexus/
graphify-out/
semantic-vector-index/
scripts/node_modules/
IGN
cp "$R1/.gitnexusignore" "$TMP_DIR/gitnexusignore.orig"
cp "$R1/.gitignore" "$TMP_DIR/gitignore.orig"

run_installer "$R1"
cmp -s "$R1/.gitnexusignore" "$TMP_DIR/gitnexusignore.orig" \
  || fail ".gitnexusignore was modified on install (custom excludes lost)"
cmp -s "$R1/.gitignore" "$TMP_DIR/gitignore.orig" \
  || { diff "$TMP_DIR/gitignore.orig" "$R1/.gitignore" >&2 || true; fail ".gitignore changed although every entry already existed (dangling header?)"; }

run_installer "$R1"
cmp -s "$R1/.gitnexusignore" "$TMP_DIR/gitnexusignore.orig" || fail ".gitnexusignore modified on re-run"
cmp -s "$R1/.gitignore" "$TMP_DIR/gitignore.orig" || fail ".gitignore modified on re-run"

# --- Case 2: fresh repo → template written; re-run idempotent
R2="$(new_repo fresh)"
run_installer "$R2"
[[ -s "$R2/.gitnexusignore" ]] || fail "fresh repo: .gitnexusignore template not written"
grep -Fxq "node_modules/" "$R2/.gitnexusignore" || fail "fresh repo: template content missing"
for e in "$HEADER" ".gitnexus/" "graphify-out/" "semantic-vector-index/" "scripts/node_modules/"; do
  grep -Fxq "$e" "$R2/.gitignore" || fail "fresh repo: .gitignore missing '$e'"
done
cp "$R2/.gitignore" "$TMP_DIR/fresh.gitignore"
cp "$R2/.gitnexusignore" "$TMP_DIR/fresh.gitnexusignore"
run_installer "$R2"
cmp -s "$R2/.gitignore" "$TMP_DIR/fresh.gitignore" || fail "fresh repo: .gitignore not idempotent"
cmp -s "$R2/.gitnexusignore" "$TMP_DIR/fresh.gitnexusignore" || fail "fresh repo: .gitnexusignore not idempotent"

# --- Case 3: partial .gitignore → only missing entries appended, under one header, nothing removed
R3="$(new_repo partial)"
printf 'dist/\n.gitnexus/\n' > "$R3/.gitignore"
run_installer "$R3"
[[ "$(grep -Fxc "$HEADER" "$R3/.gitignore")" == "1" ]] || fail "partial: header count != 1"
[[ "$(grep -Fxc ".gitnexus/" "$R3/.gitignore")" == "1" ]] || fail "partial: .gitnexus/ duplicated"
grep -Fxq "dist/" "$R3/.gitignore" || fail "partial: existing line removed"
for e in "graphify-out/" "semantic-vector-index/" "scripts/node_modules/"; do
  grep -Fxq "$e" "$R3/.gitignore" || fail "partial: missing '$e'"
done
cp "$R3/.gitignore" "$TMP_DIR/partial.gitignore"
run_installer "$R3"
cmp -s "$R3/.gitignore" "$TMP_DIR/partial.gitignore" || fail "partial: .gitignore not idempotent"

echo "install ignore-file test passed"

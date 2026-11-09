#!/usr/bin/env bash
# Checks the end state of main in the sandbox. Run with: ./verify.sh
set -uo pipefail
cd "$(dirname "$0")/sandbox/clipstr" 2>/dev/null || { echo "Run ./setup.sh first"; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
has() { grep -qE "$2" "$1"; }

echo "== Git state =="
check "you are on main"                                   test "$(git branch --show-current)" = main
check "no merge is half-finished"                         test ! -e .git/MERGE_HEAD
check "working tree is clean"                             test -z "$(git status --porcelain)"
for b in aliases ratelimit container; do
  check "feature/$b is merged into main"                  bash -c "git branch --merged main | grep -q feature/$b"; done
check "no conflict markers left in any tracked file"      bash -c "! git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- . "

echo "== Nobody's work was lost =="
check "config.yaml: alias length limit (Priya)"           has config.yaml '^  max_alias_length: 32'
check "config.yaml: rate limit per minute (Tomas)"        has config.yaml '^  rate_per_minute: 60'
check "config.yaml: original url length limit survived"   has config.yaml '^  max_url_length: 2048'
check "config.yaml: both feature flags (aliases and ratelimit)" bash -c "grep -qE '^  aliases: true' config.yaml && grep -qE '^  ratelimit: true' config.yaml"
check "config.yaml: port 80 (Maya)"                       has config.yaml '^  port: 80$'
check "requirements.txt: pydantic and slowapi, once each" bash -c "[ \$(grep -c '^pydantic' requirements.txt) = 1 ] && [ \$(grep -c '^slowapi' requirements.txt) = 1 ] && grep -q '^fastapi' requirements.txt && grep -q '^uvicorn' requirements.txt"
check "Dockerfile: --no-cache-dir (Tomas)"                has Dockerfile 'no-cache-dir'
check "Dockerfile: non-root user (Maya)"                  bash -c "grep -q 'adduser' Dockerfile && grep -q '^USER ' Dockerfile"
check "Dockerfile: two workers on port 80 (Maya)"         bash -c "grep -q -- '--workers' Dockerfile && grep -q '\"80\"' Dockerfile"
check "Dockerfile: the pip install line appears exactly once" test "$(grep -c 'pip install' Dockerfile)" = 1
check "app.py: shorten() accepts alias AND ip"            has app.py 'def shorten\(url.*alias.*ip|def shorten\(url.*ip.*alias'
check "app.py compiles"                                   python3 -m py_compile app.py

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"

#!/usr/bin/env bash
# Creates the Clipstr repository with three open feature branches in ./sandbox/clipstr (re-run to start over).
set -euo pipefail
cd "$(dirname "$0")"
rm -rf sandbox; mkdir -p sandbox/clipstr; cd sandbox/clipstr
git init -q -b main; git config commit.gpgsign false
as() { local n="$1"; shift; GIT_AUTHOR_NAME="$n" GIT_AUTHOR_EMAIL="${n%% *}@clipstr.dev" GIT_COMMITTER_NAME="$n" GIT_COMMITTER_EMAIL="${n%% *}@clipstr.dev" "$@"; }
git config user.name "$(git config --global user.name 2>/dev/null || echo You)"; git config user.email "$(git config --global user.email 2>/dev/null || echo you@example.com)"

cat > config.yaml <<'Y'
app:
  name: clipstr
  port: 8000
limits:
  max_url_length: 2048
features:
  qr: false
Y
printf 'fastapi==0.115.5\nuvicorn==0.32.1\n' > requirements.txt
cat > Dockerfile <<'D'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
D
cat > app.py <<'P'
def shorten(url):
    return "abc123"
P
git add -A; as "Maya Santos" git commit -q -m "Clipstr baseline"

git switch -q -c feature/aliases
sed -i.b 's/^  max_url_length: 2048/  max_url_length: 2048\n  max_alias_length: 32/; s/^  qr: false/  qr: false\n  aliases: true/' config.yaml
printf 'pydantic==2.10.3\n' >> requirements.txt
sed -i.b 's/def shorten(url):/def shorten(url, alias=None):/' app.py; rm -f *.b
git add -A; as "Priya Nair" git commit -q -m "Custom aliases for short links"

git switch -q main; git switch -q -c feature/ratelimit
sed -i.b 's/^  max_url_length: 2048/  max_url_length: 2048\n  rate_per_minute: 60/; s/^  qr: false/  qr: false\n  ratelimit: true/' config.yaml
printf 'slowapi==0.1.9\n' >> requirements.txt
sed -i.b 's/RUN pip install -r requirements.txt/RUN pip install --no-cache-dir -r requirements.txt/' Dockerfile
sed -i.b 's/def shorten(url):/def shorten(url, ip=None):/' app.py; rm -f *.b
git add -A; as "Tomas Costa" git commit -q -m "Rate limiting per client IP"

git switch -q main; git switch -q -c feature/container
sed -i.b 's/^  port: 8000/  port: 80/' config.yaml
sed -i.b 's/RUN pip install -r requirements.txt/RUN pip install -r requirements.txt \&\& adduser --system clipstr\nUSER clipstr/; s/"--port", "8000"\]/"--port", "80", "--workers", "2"]/' Dockerfile; rm -f *.b
git add -A; as "Maya Santos" git commit -q -m "Run as a non-root user with two workers"

git switch -q main
echo "Ready: $(pwd)"
git branch

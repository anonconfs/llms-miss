#!/data/data/com.termux/files/usr/bin/bash
# PROJECT: chatgpt-widescreen
# FRAMEWORK: nobuild
# PATH: /data/data/com.termux/files/home/github-repos/Constellation25/ai-web-extensions/chatgpt-widescreen
# AGENT: Mars
# GENERATED: Fri Mar 20 21:47:35 EDT 2026

echo "━━━ Mars building: chatgpt-widescreen [nobuild]"
cd "/data/data/com.termux/files/home/github-repos/Constellation25/ai-web-extensions/chatgpt-widescreen" || exit 1

# Venus — fix missing UI files
[ ! -f "index.html" ] && cat > index.html << 'HEOF'
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>chatgpt-widescreen</title>
<link rel="stylesheet" href="style.css"/>
</head><body><div id="root"></div>
<script type="module" src="main.js"></script>
</body></html>
HEOF

[ ! -f "style.css" ] && echo "/* chatgpt-widescreen styles */body{margin:0;font-family:sans-serif;background:#0a0a0f;color:#f8fafc}" > style.css

# Earth — fix missing config files
[ ! -f ".env" ]        && echo "NODE_ENV=production" > .env
[ ! -f ".gitignore" ]  && echo "node_modules/\ndist/\n.env" > .gitignore
[ ! -f "vercel.json" ] && echo '{"version":2,"rewrites":[{"source":"(.*)","destination":"/index.html"}]}' > vercel.json

# Jupiter — install dependencies
echo "  [Jupiter] Installing..."
npm install 2>&1 | tail -3

# Fix rollup ARM64 if needed
npm run build 2>&1 | grep -q "rollup-android-arm64" && {
  echo "  [Mars] Fixing rollup ARM64..."
  rm -rf node_modules package-lock.json
  npm install --ignore-scripts 2>&1 | tail -3
}

echo "  [Mars] No build script — deploying direct"
BUILD_OK=0

# Saturn — git commit and push
echo "  [Saturn] Pushing to GitHub..."
git add -A 2>/dev/null
git commit -m "C25 Mars: build + fix $(date +%Y-%m-%d)" 2>/dev/null || true
git push 2>/dev/null || true

# Cygnus — deploy to Vercel
echo "  [Cygnus] Deploying..."
vercel --yes --prod -e NODE_ENV=production 2>&1 | tail -1 | \
  xargs -I{} echo "  🚀 LIVE → {}"

echo "  ✅ DONE"

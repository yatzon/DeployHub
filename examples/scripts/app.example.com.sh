#!/bin/bash
# Next.js app behind nginx, managed by pm2. Clean build every time.
set -e
APP_DIR=/srv/apps/web
echo "Deploying app.example.com..."
cd "$APP_DIR"
git stash && git pull origin main
echo "Cleaning build artifacts..."
rm -rf .next node_modules
npm ci || npm install
npm run build
pm2 reload web-example --update-env
echo "Done."

#!/bin/bash
# Static SPA (Vite): build, then publish dist/ to the nginx web root.
set -e
APP_DIR=/srv/apps/dashboard
DEST_DIR=/var/www/html/dashboard
echo "Deploying dashboard.example.com..."
cd "$APP_DIR"
git stash && git pull origin main
npm install
npm run build
sudo mkdir -p "$DEST_DIR"
sudo cp -r dist/* "$DEST_DIR/"
sudo chown -R www-data:www-data "$DEST_DIR"
echo "Done."

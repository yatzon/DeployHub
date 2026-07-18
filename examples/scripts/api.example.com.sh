#!/bin/bash
# Node/Express API behind nginx, managed by pm2 (cluster).
set -e
APP_DIR=/srv/apps/api
echo "Deploying api.example.com..."
cd "$APP_DIR"
git stash && git pull origin main
npm install
npm run build
pm2 reload api-example --update-env
echo "Done."

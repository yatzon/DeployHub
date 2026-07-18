#!/bin/bash
# Go service: compile a fresh binary atomically, then restart via pm2.
set -e
APP_DIR=/srv/apps/relay
echo "Deploying relay.example.com..."
cd "$APP_DIR"
git stash && git pull origin main
echo "Building Go binary..."
go build -o relay-server.new ./cmd/server
mv relay-server.new relay-server
pm2 restart relay --update-env
echo "Done."

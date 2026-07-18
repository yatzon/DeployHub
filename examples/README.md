# Example deploy scripts

Copy any of these into your `SCRIPTS_DIR`, edit the paths and names, and they
appear in the DeployHub menu automatically.

| File                        | Pattern                                        |
| --------------------------- | ---------------------------------------------- |
| `api.example.com.sh`        | Node/Express API, pm2 cluster, zero-downtime reload |
| `app.example.com.sh`        | Next.js app, clean build (`rm -rf .next node_modules`), pm2 reload |
| `dashboard.example.com.sh`  | Static Vite SPA, publishes `dist/` to an nginx web root |
| `relay.example.com.sh`      | Go service, atomic binary build, pm2 restart   |

Each one declares `APP_DIR=` (and `DEST_DIR=` for the static one) so the menu
can read them. Swap in your real directories, repo branches, and pm2 names.

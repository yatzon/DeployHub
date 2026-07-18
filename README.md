<div align="center">

# 🚀 DeployHub

### Ship every app on your server from one clean menu.

**Stop `cd`-ing around your box at 2 a.m. trying to remember which app needs `npm ci` and which one needs a Go rebuild.**
DeployHub turns your existing deploy scripts into a fast, colour-coded control center — deploy, restart, tail logs, and edit configs for every service, without leaving one screen.

*Single file. Zero dependencies. MIT licensed. Works on any Linux server you already own.*

```text
=================================================
            DeployHub  ·  your whole server
=================================================

  -- Deployable --
   1) api.example.com          ● online   [restart]
   2) app.example.com          ● online   [clean][npm-ci][reload]
   3) dashboard.example.com    ○ --       [dist]
   4) relay.example.com        ● online   [go][restart]

  -- No script yet --
   5) background-worker               [+ add script]

  g) global/server actions    q) quit
  select #, g, q:  _
```

</div>

---

## Why teams use DeployHub

You don't need a $50/month PaaS, a Kubernetes cluster, or a CI vendor to run a
handful of apps well. You need to stop making silly mistakes on the server you
already have. DeployHub is the missing cockpit for the classic
**one-VPS, several-apps** setup — the reality for most side projects, agencies,
indie SaaS, and internal tools.

| Without DeployHub                                                    | With DeployHub                                   |
| -------------------------------------------------------------------- | ------------------------------------------------ |
| `cd` into the right folder, hope you remember the build steps        | Pick a number. It runs the right script.         |
| "Did I `rm -rf .next` before building this one?"                     | The `[clean]` badge tells you before you deploy. |
| `pm2 logs`, `pm2 restart`, `nano .env` — three commands, three paths | All one keypress away, per service.              |
| New teammate has no idea how anything deploys                        | The menu *is* the documentation.                 |
| Deploy logic drifts from a wiki page nobody updates                  | Your script is the only source of truth.         |

---

## Features

* 🎛️ **One menu for every app** — Node, Next.js, static SPAs, Go binaries, anything with a shell script.
* 🔎 **Reads your scripts, doesn't replace them** — it greps `APP_DIR`, `DEST_DIR`, and the pm2 app/action straight out of each script. No new config format to learn, nothing to keep in sync.
* 🏷️ **At-a-glance badges** — `[clean]` `[npm-ci]` `[go]` `[dist]` `[reload]` `[local-pkg]` … see exactly what a deploy will do *before* you run it.
* 🟢 **Live process status** — online / down for every pm2-managed service, right in the list.
* ⚡ **Per-service actions** — deploy, quick zero-downtime reload, edit `.env`, edit `ecosystem.config.js`, tail logs, live logs, drop into the project shell, restart/stop/start.
* ➕ **Self-completing** — got an app but no deploy script yet? DeployHub scaffolds a starter for you, opens it in your editor, and the app promotes itself to "deployable" the moment you save.
* 🌐 **Server-wide tools** — `pm2 save/resurrect`, `nginx -t && reload`, disk & memory, open ports — in the global menu.
* 📦 **Single file, no dependencies** — one bash script. Copy it to your server and run it. That's the install.

---

## Use cases

**🧑‍💻 The indie hacker / solo founder**
Five apps on a $12 droplet — a marketing site, an API, a dashboard, a landing
page, a background worker. DeployHub is the difference between "deploying is a
chore I avoid" and "deploying is one keypress."

**🏢 The small agency**
You host a dozen client sites on shared servers. New developers onboard by
opening the menu — every deploy, every log, every config is discoverable
without a runbook. No more "ask Priya, she's the only one who knows how the
staging box works."

**🛠️ The internal-tools team**
Admin panels, cron workers, a couple of Go microservices behind nginx.
DeployHub gives ops-lite engineers a safe, legible console without standing up
heavyweight platform tooling.

**🚦 The "we outgrew manual, but not ready for CI/CD" team**
You're past `scp` and `pm2 restart` from memory, but a full pipeline is
overkill. DeployHub is the pragmatic middle: your scripts, one control surface,
zero vendor lock-in.

---

## 60-second quickstart

```bash
# 1. Grab the one file
curl -fsSLO https://raw.githubusercontent.com/yatzon/DeployHub/main/deployhub.sh
chmod +x deployhub.sh

# 2. Point it at a scripts folder (default: ~/deploy-scripts)
mkdir -p ~/deploy-scripts

# 3. Drop in a deploy script (see examples/scripts/ for copy-paste starters)
cat > ~/deploy-scripts/api.example.com.sh <<'EOF'
#!/bin/bash
set -e
APP_DIR=/srv/apps/api
cd "$APP_DIR"
git stash && git pull origin main
npm install && npm run build
pm2 reload api-example --update-env
EOF
chmod +x ~/deploy-scripts/api.example.com.sh

# 4. Launch
./deployhub.sh
```

Your app is now in the menu. Press its number → **1) Deploy**. Done.

---

## How it works

Most "deploy tools" make you re-describe every app in *their* config format —
which promptly drifts out of sync with the script that actually deploys the
app. Now you're maintaining two truths.

**DeployHub inverts that.** You already write a normal shell script to deploy
each app. DeployHub:

1. **Discovers** every `*.sh` in your scripts directory and lists it.
2. **Reads facts out of the script** — `APP_DIR=`, optional `DEST_DIR=`, and the
   `pm2 restart|reload NAME` line — by grepping it.
3. **Deploys by running that script**, verbatim. No reimplementation. No drift.
4. **Badges each entry** with the steps it detects, so the menu shows what will
   happen at a glance.

There is exactly **one source of truth: your script.** DeployHub is a polished
layer on top of it — never a replacement, never a second config to babysit.

---

## Requirements

**On the server:**

* **bash 4+** — standard on every modern Linux. (macOS ships 3.2; `brew install bash` if you want it there.)
* **git** — used by typical deploy scripts (`git pull`).
* **[PM2](https://pm2.keymetrics.io/)** *(recommended)* — powers the live status column, log tailing, and restart/reload actions. `npm install -g pm2`. Apps not under pm2 still deploy fine; they just show `n/a` for status.
* Whatever **your own scripts** need — Node/npm, the Go toolchain, etc. DeployHub itself needs none of it; it only runs your scripts.

**Optional (used by the global menu):** `nginx`, and `ss` or `netstat`.

DeployHub has **no runtime dependencies of its own** beyond bash and coreutils.

---

## Install

**Option A — clone the repo**

```bash
git clone https://github.com/yatzon/DeployHub.git
cd DeployHub && chmod +x deployhub.sh && ./deployhub.sh
```

**Option B — one file, no repo**

```bash
curl -fsSLO https://raw.githubusercontent.com/yatzon/DeployHub/main/deployhub.sh
chmod +x deployhub.sh && ./deployhub.sh
```

On first run it creates your scripts directory if it doesn't exist.

---

## Configure

Two lines at the top of `deployhub.sh`:

```bash
SCRIPTS_DIR="${DEPLOYHUB_SCRIPTS_DIR:-$HOME/deploy-scripts}"
EDITOR="${EDITOR:-nano}"
```

* **`SCRIPTS_DIR`** — where your deploy scripts live. Override per run:
  `DEPLOYHUB_SCRIPTS_DIR=/srv/deploy-scripts ./deployhub.sh`
* **`EDITOR`** — editor for the edit-`.env` / edit-script actions.

That's the entire configuration. Everything else is read from your scripts.

---

## Writing a deploy script

A DeployHub-friendly script is just a normal deploy script that declares one or
two variables so the menu can read them:

* **`APP_DIR=`** — the project directory *(required)*.
* **`DEST_DIR=`** — the publish target for static sites *(optional)*.

Plus, for pm2-managed apps, a `pm2 reload NAME --update-env` (or `restart`)
line, which DeployHub reads to drive status and quick actions.

```bash
#!/bin/bash
set -e
APP_DIR=/srv/apps/api
cd "$APP_DIR"
git stash && git pull origin main
npm install
npm run build
pm2 reload api-example --update-env
```

Make it executable — it appears in the menu automatically. Copy-paste starters
for **Node, Next.js, static SPA, and Go** live in [`examples/scripts/`](examples/scripts).

---

## Badges

DeployHub greps each script and labels what a deploy will do:

| Badge         | Triggered by                     | Meaning                                |
| ------------- | -------------------------------- | -------------------------------------- |
| `[clean]`     | `rm -rf .next`                   | Wipes build cache before building      |
| `[npm-ci]`    | `npm ci`                         | Clean, lockfile-exact install          |
| `[force]`     | `npm i -f`                       | Forced install (peer-dep overrides)    |
| `[local-pkg]` | `npm i ../something`             | Links a local package — build it first |
| `[theme]`     | `build-theme` / `generate-theme` | Runs a theme generation step           |
| `[dist]`      | `cp -r dist/`                    | Publishes a Vite `dist` build          |
| `[build]`     | `cp -r build/`                   | Publishes a CRA `build` build          |
| `[go]`        | `go build`                       | Compiles a Go binary                   |
| `[reload]`    | `pm2 reload`                     | Zero-downtime reload                   |
| `[restart]`   | `pm2 restart`                    | Hard restart                           |

Badge rules live in `script_badges()` — **add your own** for your conventions
(a `[docker]` badge, a `[migrate]` badge, whatever your team uses).

---

## Self-completing: from "no script" to "fully managed"

Register apps that don't have a deploy script yet in the `SCRIPTLESS` array:

```bash
SCRIPTLESS=(
  "worker.sh|background-worker|node|/srv/apps/worker|worker"
  "engine.sh|engine (Go)|go|/srv/apps/engine|engine"
)
```

Format: `scriptFileName | Display Name | kind | APP_DIR | PM2_NAME`
(`kind` = `generic` | `node` | `go`; use `-` for `PM2_NAME` if not on pm2).

They appear in a **"No script yet"** section with a **Create deploy script**
action that scaffolds a starter tuned to the `kind`, opens it in your editor,
and — because the file now exists — **auto-promotes** the app into the
deployable list on the next refresh. A smooth path from "I have an app" to
"fully managed," without ever leaving the menu.

---

## Optional: launch on login

Want the menu when you SSH in — safely, so it never breaks `scp`/`rsync` or
non-interactive commands? Add to `~/.bashrc`:

```bash
# DeployHub on interactive login: 2s pause, 'y'+Enter launches, Enter skips.
if [[ $- == *i* ]] && [[ -n "$PS1" ]] && [[ -t 0 ]] && [[ -z "$DEPLOYHUB_SHOWN" ]]; then
    export DEPLOYHUB_SHOWN=1
    sleep 2
    read -t 5 -rp "Launch DeployHub? ('y'+Enter launches, Enter skips): " _a
    [[ "$_a" =~ ^[Yy]$ ]] && ~/deployhub.sh
fi
```

Or just alias it: `echo "alias hub='~/deployhub.sh'" >> ~/.bashrc`

---

## FAQ

**Does it store config about my apps?**
Only the optional `SCRIPTLESS` array. Everything else is read live from your
scripts each time the menu draws — nothing to keep in sync.

**Can I use it without PM2?**
Yes. Scripts still deploy; you lose the live status column and pm2-specific
actions for those services.

**Does it manage nginx / SSL / DNS?**
No. DeployHub runs *your* scripts. If a script publishes to an nginx web root,
that's your script. The only nginx touch is the optional "nginx -t & reload"
convenience.

**Is "Deploy" safe?**
It runs your script exactly as if you typed `bash yourscript.sh`, after a
confirmation prompt. DeployHub adds nothing to your scripts — read them, own them.

**How do I add an app?**
Drop a `*.sh` in your scripts directory (or register it in `SCRIPTLESS` and use
"Create deploy script"). It appears on the next refresh.

---

## Contributing

Issues and PRs welcome — especially new badge patterns and scaffold templates.
Keep it **single-file and dependency-free**.

## License

[MIT](LICENSE) — use it, fork it, ship it. No warranty.

<div align="center">
<sub>Built for everyone still running real apps on real servers. ⚙️</sub>
</div>

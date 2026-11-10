# Docker Sandbox Kit

Standardised agentic development environment using Docker Sandboxes.

## T3 Code at the heart

The sandbox runs [T3 Code](https://github.com/pingdotgg/t3code), a web UI for managing your coding agents end-to-end.

T3 Code gives you:

- **Threads**: a conversation per task, each with its own agent session
- **Git worktrees**: work across multiple branches without switching contexts or stashing changes
- **Orchestration**: delegate subtasks to other agents and models from a single thread
- **Status overview**: a live view of what each agent is doing

The kit is a mixin for Docker's Claude Code sandbox. It bakes in a pinned T3 Code release (see `kit/t3code/t3code.dockerfile`) and exposes port 3773. The environment file below makes `sbx env run` start T3 Code in your terminal, from the sandbox workspace, which it adds as a project on first start.

T3 Code runs in the foreground, so it runs only while `sbx env run` is attached. Closing that terminal stops T3 Code and the agent threads it's running, and `sbx env run --detach` starts the sandbox without it.

## Setup

**1. Install Docker Sandboxes**

Requires v0.51 or later.

```
https://docs.docker.com/ai/sandboxes/get-started
```

**2. Start the sandbox**

Kits from GitHub must be allowed first (one time). This replaces the default list, which only allows Docker Hub:

```bash
sbx settings set kit.allowedSources '["docker.io/","github.com/nickschuch/"]'
```

Then describe the sandbox in an [environment file](https://docs.docker.com/ai/sandboxes/configuration/environment-files/). Save it as `sbxenv.yaml` next to your project directory, not inside it, so the agent can't change it:

```yaml
schemaVersion: "1"
agent: sbx-kit-claude
workspace: ./my-project

# Run T3 Code, not Claude Code's terminal UI, when you run `sbx env run`.
entrypoint: [t3, serve, --host, 0.0.0.0, --port, "3773", --auto-bootstrap-project-from-cwd]
cmd: []

env:
  # Label Claude requests as T3 Code instead of sdk-cli/sdk-ts, which drain
  # the 5-hour usage window faster. Remove once this lands upstream:
  # https://github.com/pingdotgg/t3code/pull/25597
  CLAUDE_CODE_ENTRYPOINT: t3-code

kits:
  # Claude Code workload: the base the T3 Code mixin lands on.
  - docker/sbx-kit-claude:2.1.316
  - git+https://github.com/nickschuch/sbx.git#dir=kit/t3code

ports:
  - sandbox: 3773
    host: 3773
```

Set `workspace` to your project directory, relative to the file. The T3 Code kit is a v3 mixin, so the set needs a v3 workload kit to land on: the built-in `claude` agent won't do, which is why the file lists `docker/sbx-kit-claude` and names it in `agent`. That workload's own entrypoint is Claude Code's terminal UI, and a mixin can't replace it, so `entrypoint` and `cmd` replace it with `t3 serve`:

- `--host 0.0.0.0` listens on all interfaces, so the published port can reach T3 Code.
- `--auto-bootstrap-project-from-cwd` adds the workspace, where `sbx env run` starts, as a project.
- `cmd: []` clears any default arguments from the workload.

Claude Code is still installed: `sbx exec -it <sandbox> -- claude` opens it. Then, from the directory holding `sbxenv.yaml`, review the plan and start the sandbox:

```bash
sbx env plan
sbx env run
```

Leave `sbx env run` open: it's T3 Code's server and log. Run the commands in the following steps from a second terminal. The steps below use `<sandbox>` as the sandbox name. Find it with:

```bash
sbx ls
```

**3. Check the port**

The environment file publishes T3 Code on `localhost:3773`. Confirm with:

```bash
sbx ports <sandbox>
```

**4. Log in to Claude (one time)**

Agents in the sandbox need their own Claude login:

```bash
sbx exec -it <sandbox> -- claude auth login
```

Follow the link it prints, then paste the code back into the terminal.

**5. Pair your browser with T3 Code (one time)**

T3 Code only lets in browsers that have paired with a one-time token, and this can't be turned off: it listens on all interfaces so the published port can reach it, and T3 Code requires pairing whenever it does. You only pair once per browser or device; after that, the browser stays signed in with a session cookie.

`t3 serve` prints pairing details when it starts, in the `sbx env run` terminal. Open http://localhost:3773 and pair with the link or token it prints.

To pair a second device, or if the token has expired, mint a new one while T3 Code is running:

```bash
sbx exec -it <sandbox> -- t3 pair --label "$(hostname)"
```

- Tokens expire after 5 minutes. Add `--ttl 1h` for longer, for example to scan the QR code from a phone later.
- Earlier tokens can't be read back: `t3 auth pairing list` hides their secrets, so mint a new one instead of looking for an old one.
- Pairing tokens are one-time sign-in links. Treat them like passwords until they expire.

**6. Optional: link T3 Connect (one time)**

To reach the sandbox from your other devices and get push notifications, link it to T3 Connect, then restart the sandbox so the link takes effect:

```bash
sbx exec -it <sandbox> -- t3 connect link --headless
sbx stop <sandbox>
sbx env run
```

Check the connection with `sbx exec <sandbox> -- t3 connect status`.

**7. Connect MCP servers (optional)**

Claude Code in the sandbox, including the agents T3 Code starts, uses the [Docker Sandboxes MCP gateway](https://docs.docker.com/ai/sandboxes/mcp-gateway/). Register servers on your host with `sbx mcp add`. Credentials stay in your host's credential store and never enter the sandbox.

```bash
sbx mcp add <server> --url <url>
sbx mcp load <server> --sandbox <sandbox>
```

**8. Start working**

- T3 Code: http://localhost:3773
- Sandbox TUI: `sbx`

## Troubleshooting

**`sbx env run` opens Claude Code instead of T3 Code.** Check that `sbxenv.yaml` has the `entrypoint` and `cmd` lines from step 2.

**http://localhost:3773 doesn't load.** T3 Code only runs while `sbx env run` is open. Check that terminal is still running, then check the port (step 3).

**A second `sbx env run` says port 3773 is in use.** Each `sbx env run` starts its own `t3 serve`, and only one can hold the port. Use the T3 Code that's already running, or close its terminal first.

**The pairing token was rejected.** It has probably expired or already been used. Mint a new one (step 5).

Have T3 Code inspect and repair its data directory:

```bash
sbx exec <sandbox> -- t3 doctor
```

## Roadmap

* Default mcp server configuration
* Baked in skills
* Token saving projects/plugins

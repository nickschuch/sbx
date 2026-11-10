# Docker Sandbox Kit

Standardised agentic development environment using Docker Sandboxes.

## T3 Code at the heart

The sandbox runs [T3 Code](https://github.com/pingdotgg/t3code), a web UI for managing your coding agents end-to-end.

T3 Code gives you:

- **Threads**: a conversation per task, each with its own agent session
- **Git worktrees**: work across multiple branches without switching contexts or stashing changes
- **Orchestration**: delegate subtasks to other agents and models from a single thread
- **Status overview**: a live view of what each agent is doing

The kit is a mixin for Docker's Claude Code sandbox. It bakes in a pinned T3 Code release (see `kit/t3code/t3code.dockerfile`) and, on each sandbox start, serves it on port 3773, from the sandbox workspace (`$WORKSPACE_DIR`), which it adds as a project on first start.

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

Then, from your project directory:

```bash
sbx run claude --kit "git+https://github.com/nickschuch/sbx.git#dir=kit/t3code"
```

The steps below use `<sandbox>` as the sandbox name. Find it with:

```bash
sbx ls
```

**3. Find the port**

sbx publishes port 3773 to a random port on your host. Find it with:

```bash
sbx ports <sandbox>
```

To use a fixed port instead, publish it yourself. The steps below assume `localhost:3773`:

```bash
sbx ports <sandbox> --publish 3773:3773/tcp
```

**4. Log in to Claude (one time)**

Agents in the sandbox need their own Claude login:

```bash
sbx exec -it <sandbox> -- claude auth login
```

Follow the link it prints, then paste the code back into the terminal.

**5. Pair your browser with T3 Code (one time)**

T3 Code runs headless, so each browser or device has to be paired once. Mint a pairing token:

```bash
sbx exec -it <sandbox> -- t3 pair --label "$(hostname)"
```

Open http://localhost:3773 and pair with the link or token it prints. Tokens expire after 5 minutes; run the command again if yours has expired.

**6. Optional: link T3 Connect (one time)**

To reach the sandbox from your other devices and get push notifications, link it to T3 Connect, then restart the sandbox so the link takes effect:

```bash
sbx exec -it <sandbox> -- t3 connect link --headless
sbx stop <sandbox>
sbx run <sandbox>
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

Have T3 Code inspect and repair its data directory:

```bash
sbx exec <sandbox> -- t3 doctor
```

## Roadmap

* Default mcp server configuration
* Baked in skills
* Token saving projects/plugins

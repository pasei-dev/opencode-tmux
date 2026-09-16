# opencode-tmux

OpenCode v2 plugin that manages subagent sessions in tmux panes.

## Overview

When OpenCode runs inside tmux, this plugin spawns each subagent as a sibling pane attached to the same OpenCode server. Child sessions open in new tmux panes while resumed sessions reuse existing tracked panes. Panes clean up automatically when sessions end.

## Behaviors

- **Task queuing**: Intercepts `task` tool calls from parent sessions inside tmux and queues them for child spawning.
- **Sibling pane spawning**: Opens each child session in a new tmux pane split from the existing pane layout.
- **Resumed session reuse**: Finds and reuses tracked panes for sessions that resume (identified by `task_id` matching the session ID).
- **Pane ordering**: First delegated pane opens as a horizontal split. Subsequent panes append as vertical splits below the existing stack, so the oldest pane stays at the top and newer panes appear below.
- **Explicit cleanup**: Closes panes immediately on `session.deleted` events.
- **Deferred cleanup**: Schedules pane closure after `session.idle` with a short delay (4s) and a fresh-pane guard (5s) to prevent flicker when sessions open and close rapidly.
- **Process shutdown**: Immediate pane cleanup attempts a graceful process termination before closing the tmux pane. Deferred idle cleanup closes the pane directly.

## Requirements

- **OpenCode v2** (`@opencode/plugin` v2 API).
- **tmux**: Must be installed and on PATH.
- **Parent session inside tmux**: the `TMUX` environment variable must be set (i.e. the OpenCode server was started from inside tmux).

Each pane runs `opencode --session <id> <dir>` against the shared background service, so no server URL is needed. If `OPENCODE_SERVER_URL` is set it is forwarded via `--server`; otherwise service discovery handles it. `OPENCODE_BIN` may point at a specific binary.

## Install

```sh
opencode plugin add github:Nejrup/opencode-tmux
```

```jsonc title="opencode.jsonc"
{
  "plugins": ["github:Nejrup/opencode-tmux"],
}
```

```sh
opencode service restart
```

Check it took:

```sh
opencode plugin list
# ID     VERSION  SOURCE
# tmux   <sha>    github:Nejrup/opencode-tmux
```

> **Pin a version:** append a ref — `github:Nejrup/opencode-tmux#v2.0.0`.
> An unpinned spec tracks the default branch and `opencode plugin update` moves it;
> exact versions and full commit hashes stay put and are skipped by update checks.

## Local verification

Install dependencies and run the available checks:

```bash
npm install
npm run check:env
npm run typecheck
```

`check:env` validates the expected local environment. `typecheck` is the static check for the plugin code.

## Manual smoke test

Verify the full pane spawn and cleanup flow in a live tmux session:

1. Register this checkout (`./install.sh`) or install from GitHub (see above).
2. Start OpenCode from inside tmux.
3. Trigger a `task` tool call that creates a child session.
4. Confirm a sibling pane appears for the child session.
5. Confirm the pane closes on `session.deleted` or after the idle cleanup delay.

## Entry point

- Source: [`src/index.ts`](src/index.ts)
- Plugin ID: `tmux` (server-only, no TUI half)

## Development

Local development install (registers this checkout via `git+file://`, like `opencode-profile-switcher`'s dev loop):

```sh
./install.sh
```

After editing `src/`: commit, then `opencode plugin update` (or remove + add) and `opencode service restart`.

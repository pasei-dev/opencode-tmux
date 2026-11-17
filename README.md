<div align="center">

# opencode-tmux

**Every subagent gets its own tmux pane, next to yours.**

![OpenCode 2.3+](https://img.shields.io/badge/OpenCode-2.3%2B-black)
![license: MIT](https://img.shields.io/badge/license-MIT-black)

</div>

OpenCode runs subagents headless, so their work stays invisible until a task
returns. This plugin opens each child session in a sibling tmux pane attached to
the same server. You watch the agent work in the layout you already have.

## Install

```sh
opencode plugin add github:pasei-dev/opencode-tmux
```

```jsonc
{
  "plugins": ["github:pasei-dev/opencode-tmux"],
}
```

> [!NOTE]
> Plugins are a startup key. Restart the service after adding it.

```sh
opencode service restart
opencode plugin list
# ID     VERSION  SOURCE
# tmux   <sha>    github:pasei-dev/opencode-tmux
```

> [!NOTE]
> Pin a version by appending a ref: `github:pasei-dev/opencode-tmux#v2.0.0`. An
> unpinned spec tracks the default branch and `opencode plugin update` moves it.
> Exact versions and full commit hashes stay put and are skipped by update
> checks.

## How it works

- **Task queuing** — intercepts `task` tool calls from parent sessions inside
  tmux and queues them for child spawning.
- **Sibling panes** — each child session opens in a pane split from the current
  layout, attached to the same OpenCode server.
- **Resumed sessions** — a session that resumes is matched by `task_id` against
  the tracked panes and reuses its pane instead of opening a new one.
- **Pane order** — the first delegated pane opens as a horizontal split. Later
  panes append as vertical splits below the stack, so the oldest stays on top.
- **Cleanup** — panes close immediately on `session.deleted`, and after
  `session.idle` with a 4 s delay behind a 5 s fresh-pane guard, so sessions
  that open and close quickly do not flicker.
- **Shutdown** — immediate cleanup attempts a graceful process termination
  before closing the pane. Deferred idle cleanup closes the pane directly.

## Requirements

- **OpenCode 2.3+** (`@opencode/plugin` v2 API).
- **tmux** installed and on `PATH`.
- **`TMUX` set** — the OpenCode server must be started from inside tmux.

Each pane runs `opencode --session <id> <dir>` against the shared background
service, so no server URL is needed. `OPENCODE_SERVER_URL` is forwarded via
`--server` when set; otherwise service discovery handles it. `OPENCODE_BIN`
points at a specific binary.

## Limits

- Outside tmux, or with `TMUX` unset, the plugin does nothing and subagents run
  headless as usual. There is no fallback pane layout.
- The plugin is server-only, ID `tmux`, with no TUI half. Nothing about it shows
  up in the TUI.
- A pane younger than the 5 s guard is not closed by idle cleanup. It stays
  until the session is deleted.

## Development

Local install registers this checkout via `git+file://`:

```sh
./install.sh
```

Verification:

```sh
npm install
npm run check:env
npm run typecheck
```

`check:env` confirms `tmux` and `opencode` are on `PATH`. `typecheck` is the
static check for the plugin code in [`src/index.ts`](src/index.ts).

Smoke test in a live tmux session:

1. Register the checkout with `./install.sh`, or install from
   [GitHub](https://github.com/pasei-dev/opencode-tmux).
2. Start OpenCode from inside tmux.
3. Trigger a `task` tool call that creates a child session.
4. Confirm a sibling pane appears, then closes on `session.deleted` or after the
   idle cleanup delay.

After editing `src/`: commit, then run `opencode plugin update` and
`opencode service restart`.

# opencode.md

This repo is a personal skills library for opencode. Each subdirectory that
contains a `SKILL.md` is one self-contained skill. This file explains how
to clone the repo and load every skill into opencode without hardcoding
any device-specific path.

## 1. Clone

```bash
git clone https://github.com/sleet-ai/skills.git
```

Clone it wherever you keep personal config (e.g. `~/code/skills`,
`~/projects/skills`, `~/dev/skills`). The location does not matter — the
config below is written so it works from any clone location.

## 2. Load all skills into opencode

Pick **one** scope. Project-scope config lives inside the cloned repo and
travels with it; global-scope config lives in `~/.config/opencode/` and
applies to every project.

### Option A — project scope (recommended for a portable playground)

At the root of the cloned repo, create `opencode.json` (or `opencode.jsonc`):

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    // "." resolves to the directory opencode loaded the config from,
    // so this works no matter where you cloned the repo.
    "paths": ["."]
  }
}
```

opencode walks up from `cwd` looking for this file, so any session started
inside the repo (or any subdirectory) picks up the skills automatically.

### Option B — global scope

Edit (or create) `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": ["<absolute-path-to-the-cloned-repo>"]
  }
}
```

Replace `<absolute-path-to-the-cloned-repo>` with the actual absolute path
of the cloned repo on your machine (e.g. the output of `pwd` run inside
the repo, or `realpath .` from the repo root). Do not commit your absolute
path — this file is global and per-machine.

## 3. Restart opencode

opencode loads config once at startup. After saving the config file, quit
and restart opencode for the new skills to appear in the skills list.

## 4. Updating

```bash
# inside the cloned repo
git pull
```

No config changes are needed — restart opencode after pulling to pick up
any new or changed `SKILL.md` files.

## Adding a new skill to the playground

```bash
# from the repo root
mkdir -p my-new-skill
```

Then write `my-new-skill/SKILL.md` with the required frontmatter:

```markdown
---
name: my-new-skill
description: One sentence covering what the skill does AND when to trigger it.
---

(body of the skill in markdown)
```

Required:

- `name` — lowercase, hyphen-separated, must match the folder name.
- `description` — what the skill does **and** when to use it. Skills
  without a description are filtered out and never surface to the model.

Optional: `license`, `compatibility`, `metadata`.

Restart opencode. The skill loader scans every directory under `paths`
recursively for `**/SKILL.md`, so any folder containing a valid `SKILL.md`
is picked up automatically — no further config edits required.

## Troubleshooting

- Skills not appearing after edit: you forgot to restart opencode. Quit
  and relaunch.
- opencode refuses to start: your `opencode.json` is malformed. Run with
  `OPENCODE_DISABLE_PROJECT_CONFIG=1` from the repo directory to skip
  project config while you fix it, or `OPENCODE_CONFIG=/path/to/clean.json`
  to load a temporary clean file.
- Need the authoritative schema for any field: fetch
  <https://opencode.ai/config.json>.

===============
<br/>
copyright 2026 by sleet.near
---
name: project-web3stick-sticksocial
description: Build and extend sticksocial, a SvelteKit NEAR Social UI. Use when working in the sticksocial repo, writing wrapper functions for near-social-js, building widgets that read/write to social.near, paginating feeds, or learning from the deprecated mob.near/widget/N/ProfileEditor/etc. widgets to inform new UI.
compatibility: Requires `git`, `bun`. Targets mainnet `social.near`. Browser wallet via `@near-kit-tool-box/web`; server/bins via `@near-kit-tool-box/env`.
---

# sticksocial

`web3stick/sticksocial` is a SvelteKit 2 + Svelte 5 (runes) UI for NEAR Social. Data flows through [`near-social-js`](https://github.com/NEARBuilders/near-social-js) wrappers in `src/lib/near-social-js/`, rendered by widgets in `src/lib/widgets/`, mounted from pages in `src/routes/`.

Sibling testing playground: [`sleet-js/near-social-tool-box`](https://github.com/sleet-js/near-social-tool-box). Every wrapper we add in sticksocial is first prototyped and CLI-tested there.

---

## Resources

- `web3stick/sticksocial` — the app under development (SvelteKit + Svelte 5 runes, adapter-static, Netlify).
- `sleet-js/near-social-tool-box` — the testing playground. CLI bins in `bin-env/` exercise every wrapper against live mainnet data; mirror wrappers here before adding them to sticksocial.
- `NEARBuilders/near-social-js` — the underlying TypeScript SDK against `social.near`. Read on GitHub or `npm view near-social-js`; types like `Post`, `Profile`, `Notification`, `IndexEntry` come from here.
- `@near-kit-tool-box/web` — browser-side NEAR connection + wallet helper (used by sticksocial's `auth.svelte.ts` and `near_social_client(...)` factory).
- `@near-kit-tool-box/env` — env-based NEAR client used by tool-box bins (`near_kit_env`).
- Original NEAR Social widget registry — fetch source onchain via `bun run bin-env/main/get.ts -- 'mob.near/widget/<name>'` in the tool-box. Patterns from `N`, `Homepage`, `ProfileEditor`, `ProfilePage`, `MetadataEditor`, `ImageEditorTabs` are still useful.

---

## 1. Working directory

Work on this project in a clean working directory, e.g. `sticksocial_working_directory`.

Assume the dev may have already started the agent with these repos cloned. Check first, clone only what's missing:

```bash
ls
# sticksocial/                ← required
# near-social-tool-box/       ← required (testing playground)
# near-social-js/             ← optional, useful for browsing the SDK source
# near-kit-tool-box/          ← optional, source for @near-kit-tool-box/{web,env}
```

Cloning any that are missing:

```bash
git clone https://github.com/web3stick/sticksocial.git
git clone https://github.com/sleet-js/near-social-tool-box.git
git clone https://github.com/NEARBuilders/near-social-js.git          # optional
git clone https://github.com/sleet-js/near-kit-tool-box.git          # optional
```

`near-kit` is pinned to `0.14.0` via `resolutions` in `near-social-tool-box/package.json` (see its `NOTES.md`).

---

## 2. Stack & dev commands

From `sticksocial/package.json`:

- SvelteKit 2 (`@sveltejs/kit`), Svelte 5 with **runes mode forced** for everything except `node_modules` (see `svelte.config.js`)
- Vite 8, TypeScript 6 strict, `@sveltejs/adapter-static`, Prettier + `prettier-plugin-svelte`
- Runtime: `near-social-js@^2.0.4`, `@near-kit-tool-box/web@^0.0.6`, `zod@^4.4.3`, `bootstrap-icons`, `lucide-svelte`, `marked`

```bash
cd sticksocial
bun i
bun run dev        # vite dev
bun run check      # svelte-kit sync && svelte-check
bun run tsc --noEmit
bun run format     # prettier --write .
bun run build && bun run preview

# netlify (stickyweb-sticksocial)
netlify deploy
netlify deploy --prod
```

`near-social-tool-box` uses the same bun toolchain; its `bin-env/` scripts are invoked as `bun run bin-env/main/<name>.ts -- <args>`.

---

## 3. Architecture

- `src/lib/near-social-js/new.ts` — `near_social_client(near)` factory wrapping `new Social({ near })`.
- `src/lib/near-social-js/main/fun_*.ts` — one wrapper per `near-social-js` method, each with its inline `NEAR_SOCIAL_JS_<METHOD>_OPTIONS` interface.
- `src/lib/near-social-js/helper/get_account_id_*.ts` — composite helpers that resolve a specific post/comment/profile by `(accountId, blockHeight?)`.
- `src/lib/widgets/*.svelte` — Svelte 5 widgets. `widgets/fun/` for widget helpers, `widgets/components/` for subcomponents.
- `src/lib/components/` — app-level components: `nav.svelte`, `home_nav.svelte`, `profile_nav.svelte`, `button_auth.svelte`.
- `src/lib/ts/auth.svelte.ts` — `$state`-based auth (`auth.isSignedIn`, `auth.accountId`) using `near_connect_client().wallet()`.
- `src/lib/ts/routes.ts` — `ROUTES` const consumed by nav.
- `src/lib/css/`, `src/lib/types/` — global stylesheets and shared TS types.
- `src/routes/` — SvelteKit pages. Top-level: `feed/` (with `options/`), `profile/[accountId]/`, `profile/auth/`, `profile/router/`, `settings/`, `discover/`, `notifications/`, `blank/`.

`near-social-tool-box` mirrors `src/lib/near-social-js/` and adds `bin-env/main/` + `bin-env/helper/` CLI scripts that exercise every wrapper against real mainnet data.

---

## 4. Conventions (from AGENTS.md)

These are non-negotiable for new files:

- **One wrapper per near-social-js method.** Filename `fun_<method>.ts` in `src/lib/near-social-js/main/`. Each exports a single async function.
- **Inline options interface** named `NEAR_SOCIAL_JS_<METHOD>_OPTIONS` that mirrors the upstream signature 1:1 (including `bigint` for `blockHeight`).
- **Section dividers.** Use `// ============================================` to separate interface, function, and inline log blocks. Match the spacing exactly.
- **Pretty `console.log`** of inputs and the raw upstream result, framed by `=================` lines, so bin runs are easy to scan. See `sticksocial/src/lib/near-social-js/main/fun_get_activity_feed.ts` and `near-social-tool-box/src/near-social-js/main/fun_get.ts`.
- **Auth-aware wrappers.** Browser wrappers call `near_social_client(near_kit_client())` directly (no `near` arg); server/CLI wrappers in the tool-box accept `near: Near` so bins can pass `near_kit_env`.
- **Widgets import from `$lib/near-social-js/main/fun_*`** — never call `near_social_client(...)` from a `.svelte` file.
- **Svelte 5 runes only.** `$state`, `$derived`, `$effect`, `$props`. No `let` reactivity, no stores. Filename `*.svelte`, props type `{ ... }: { foo: string } = $props()`.
- **One thing at a time.** Don't bundle unrelated fixes into a widget PR.
- **Follow existing file format** — small details (spacing, comment lines, naming) matter.

---

## 5. Widget reference from the deprecated NEAR Social UI

The original `near.social` frontend was widget-composable and source-on-chain. We can still fetch their source for inspiration via the tool-box bin:

```bash
cd ../near-social-tool-box
bun run bin-env/main/get.ts -- 'mob.near/widget/Homepage'
bun run bin-env/main/get.ts -- 'mob.near/widget/N'
bun run bin-env/main/get.ts -- 'mob.near/widget/ProfileEditor'
bun run bin-env/main/get.ts -- 'mob.near/widget/ProfilePage'
bun run bin-env/main/get.ts -- 'mob.near/widget/ProfileLarge'
bun run bin-env/main/get.ts -- 'mob.near/widget/ProfileTabs'
bun run bin-env/main/get.ts -- 'near/widget/MetadataEditor'
bun run bin-env/main/get.ts -- 'near/widget/ImageEditorTabs'
```

Verified-working widgets worth studying (see `near-social-tool-box/widgets.md`):

| Widget | Why it's useful |
| --- | --- |
| `mob.near/widget/N` | Feed with tabs (Premium / Following / All Posts) — model for `/feed` + `/feed/options` |
| `mob.near/widget/Homepage` | Pattern: read `${accountId}/settings/near.social/homepage`, fall back to default widget |
| `mob.near/widget/ProfileEditor` | Profile editing (metadata, image, linktree) — model for `/settings` |
| `mob.near/widget/ProfilePage` / `ProfileLarge` / `ProfileTabs` | Banner + tabs for posts/widgets/followers — model for `/profile/[accountId]` |
| `near/widget/MetadataEditor` / `ImageEditorTabs` | Reusable form + image picker sub-widgets |

Confirmed deprecated (return nothing): `SocialApplication`, `SocialProfile`, `TagsEditor`.

Use these as **patterns**, not as copy-paste. sticksocial is Svelte, not JSX; rebuild the ideas on top of our wrapper functions.

---

## 6. Implementing a new feature (workflow)

Order matters — every feature goes tool-box → sticksocial.

1. **Find the upstream method.** Check `near-social-js` docs/types (`Social` class) for the right call (`get`, `index`, `getActivityFeed`, `getPost`, `set`, `createPost`, etc.).
2. **Prototype the wrapper** in `near-social-tool-box/src/near-social-js/main/fun_<method>.ts`. Include the inline `NEAR_SOCIAL_JS_<METHOD>_OPTIONS` interface, section dividers, pretty `console.log`.
3. **Write a bin** at `near-social-tool-box/bin-env/main/<method>.ts` that imports the wrapper, takes `process.argv` args with **sane defaults that return real data**, and runs it. Add the example commands to `bin-env/README.md`.
4. **Run the bin.** `bun run bin-env/main/<method>.ts -- <args>` — confirm console output makes sense for the live `social.near` data. Fix the wrapper if shape is off.
5. **Mirror the wrapper** into `sticksocial/src/lib/near-social-js/main/fun_<method>.ts`. Sticksocial browser wrappers usually drop the `near` arg and use `near_kit_client()` directly.
6. **Build the widget** in `sticksocial/src/lib/widgets/<name>.svelte`. Use `Post`, `Profile`, `Notification`, `IndexEntry` types from `near-social-js`; load data via `$effect`; expose props for `limit`/`order`/`from` where it makes sense. For infinite scroll, copy the IntersectionObserver + `hasMore` pattern from `infinite_post_feed.svelte`.
7. **Mount it** from the appropriate `src/routes/<page>/+page.svelte`. Add a route entry to `src/lib/ts/routes.ts` if it's a new top-level nav destination.
8. **Run `bun run check && bun run tsc --noEmit`** in sticksocial before considering the feature done.

---

## 7. Type imports & upstream surface

Common types pulled straight from the package:

```ts
import type { Post, Profile, Notification, IndexEntry } from "near-social-js";
```

Common wrapper calls you'll see (and should mirror):

- `near_social_client(near).get({ keys, blockHeight?, ... })` → wrapper `fun_get.ts`
- `.getActivityFeed({ limit, from, order })` → `fun_get_activity_feed.ts`
- `.getAccountFeed(accountId, { ... })` → `fun_get_account_feed.ts`
- `.getPost(accountId, blockHeight)` / `.getProfile(accountId)` → `fun_get_post.ts`, `fun_get_profile.ts`
- `.createPost(signerId, post)` → `fun_create_post.ts`
- `.like({ ... })` / `.unlike({ ... })` → `fun_like.ts`, `fun_unlike.ts`
- `.follow({ ... })` / `.unfollow({ ... })` → `fun_follow.ts`, `fun_unfollow.ts`
- `.set({ data, signerId? })` → `fun_set.ts`

If the upstream `Social` method you need isn't wrapped yet, follow §6 — add it to the tool-box first.

---

## 8. Quick sanity checklist before committing

- [ ] Wrapper exists in **both** repos with matching options interface.
- [ ] Tool-box bin runs and prints a real mainnet result; example added to `bin-env/README.md`.
- [ ] Widget uses `$state`/`$effect`/`$props` only; imports wrappers from `$lib/near-social-js/main/`.
- [ ] New top-level route added to `src/lib/ts/routes.ts` and the nav component picks it up.
- [ ] `bun run check && bun run tsc --noEmit` passes.
- [ ] `bun run format` has been run.
- [ ] No unrelated drive-by edits.

===============
<br/>
copyright 2026 by sleet.near

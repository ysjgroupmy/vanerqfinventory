# 0428 Sauce Line

A single-file production-panel app (stock, cook scheduling, sales import, stocktakes,
yield tracking) for a sauce/food production line. Originally built on the Claude
Artifacts `db` capability; this version is a plain static site backed by **Supabase**
(Postgres + Realtime) for data and **Clerk** for sign-in, so it can be hosted anywhere.

Everyone who is signed in shares one live dataset per department — changes made on
one device appear on every other open tab within about a second.

## What's in this folder

- `index.html` — the whole app. One file, no build step.
- `supabase-schema.sql` — the database schema, RLS policies, and realtime setup. Run this once.
- `README.md` — this file.

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) → New project.
2. Once it's up, open **SQL Editor** → New query, paste the entire contents of
   `supabase-schema.sql`, and run it. This creates the tables (`departments`,
   `items`, `tx`, `plan`, `bills`, `settings`), turns on Row Level Security with
   policies that allow any signed-in user full read/write, enables Realtime on
   those tables, and seeds one starter department (`0428`).
3. From **Project Settings → API**, copy:
   - **Project URL** (`https://xxxxxxxx.supabase.co`)
   - **anon public** key (a long `eyJ...` JWT — not the `service_role` key, never use that one client-side)

You'll paste both into the app's setup screen later.

## 2. Create a Clerk application

1. Go to [clerk.com](https://clerk.com) → create an application (any sign-in
   method is fine — email/password, magic link, Google, etc.).
2. From the Clerk dashboard, copy the **Publishable key** (`pk_test_...` or
   `pk_live_...`). You'll paste this into the app too.
3. If you want to control who can sign in at all (this app has no per-user
   permissions — every signed-in user shares full read/write access to every
   department, same as the original "one shared line, several devices" design),
   go to **Clerk → User & Authentication → Restrictions** and turn off public
   sign-up, or set up an allowlist/invitation flow. Do this in Clerk, not in the app.

## 3. Connect Clerk and Supabase to each other

This is the step that makes Supabase trust Clerk's sign-in and treat a signed-in
Clerk user as a normal authenticated Postgres user (no JWT templates or secret-key
sharing required — this is Supabase's native "Third-Party Auth" integration):

1. In the Clerk dashboard, open **[Connect with Supabase](https://dashboard.clerk.com/setup/supabase)**
   and follow its steps for your application. This is what makes Clerk issue
   session tokens carrying `"role": "authenticated"`, which is what
   `supabase-schema.sql`'s RLS policies (`to authenticated`) check for.
2. In the Supabase dashboard, go to **Authentication → Sign In / Providers →
   Third Party Auth**, add a new **Clerk** integration, and paste in the Clerk
   domain the previous step gave you.

If you skip this step, sign-in will still work but every database read/write will
fail with a permission-denied error, because Postgres won't recognize the request
as coming from an authenticated user.

## 4. Run the app

`index.html` needs no build step — open it directly, or host it anywhere that
serves static files (Netlify, Vercel, Cloudflare Pages, GitHub Pages, S3, or just
double-click it locally).

The first time it loads in a browser, it shows a one-time setup screen asking for:

- Supabase project URL
- Supabase anon public key
- Clerk publishable key

These are saved to that browser's `localStorage` only (never sent anywhere except
straight to Supabase and Clerk) so this step is per-browser, not per-deploy — you
can hand the same `index.html` to different people and each of them configures
their own browser once. After saving, it shows Clerk's sign-in screen, and once
signed in, the app itself.

To reconfigure later (different project, wrong key, etc.), use **Setup → Change
Supabase / Clerk keys** inside the app, or the equivalent link on the sign-in screen.

## Notes on the data model

- Each **department** (e.g. `0428`, `0227`) has its own items, movement log, cook
  plan, invoice registry and settings — exactly like the original design's
  Firestore subcollections, just as Postgres rows scoped by a `dept_id` column.
- Item, movement-log and cook-plan IDs are assigned client-side by small
  per-department counters (kept in the `settings` row), not by Postgres identity
  columns. This is intentional — it's what lets every action in the app (adding
  an item, logging a cook, importing sales) update the screen immediately without
  waiting on a round trip, while a debounced background sync pushes only the rows
  that actually changed. Because the counters are per-department, `items`/`tx`/`plan`
  use a **composite primary key** `(dept_id, id)` — don't "simplify" that back to a
  plain `id` primary key, item #1 in two different departments would collide.
- Removing a department (Setup → Departments) is a real, permanent delete —
  Postgres cascades and removes its items, log, plan and settings. The original
  Firestore version only removed it from the switcher; this one is unforgiving,
  matching how a real relational schema behaves. Export a backup first.
- A copy of the current department's data is mirrored into `localStorage` purely
  so the page still shows the last-seen numbers if the connection drops — Supabase
  is always the source of truth once reachable, there's no "which copy wins"
  reconciliation flow to worry about like the original artifact version had.

## Troubleshooting

- **"Could not reach Supabase" / permission-denied errors**: almost always means
  step 3 (Clerk ↔ Supabase Third-Party Auth) isn't wired up yet, or
  `supabase-schema.sql` wasn't run.
- **Clerk sign-in screen never appears / "Could not start Clerk"**: double-check
  the publishable key was pasted in full and correctly (`pk_test_...`/`pk_live_...`).
  The app derives Clerk's script URL from that key, so a mistyped key breaks loading.
- **Realtime updates don't show up on other tabs**: confirm the `alter publication
  supabase_realtime add table ...` line at the bottom of `supabase-schema.sql`
  actually ran (check **Database → Replication** in the Supabase dashboard — all
  six tables should be listed).

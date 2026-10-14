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
   `items`, `tx`, `plan`, `bills`, `settings`, `racks`, `levels`), turns on Row Level Security with
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

## Warehouse departments (0434)

A department can be `kitchen` (the cook-line pages: Panel/Cook/Sales In/Sales)
or `warehouse` (Racks / Receive Stock / Issue Stock / Issued Summary instead).
Setup → Departments has a Type selector when adding a new one. Stock,
Stocktake, Count, Log and Setup are shared by both types.

> **Updating an existing database:** re-run `supabase-schema.sql` *before*
> opening this version on a warehouse department. It adds `items.pack_size`,
> `tx.supplier` / `tx.ref`, `racks.zone` / `x` / `y` / `w` / `h` / `floor` and
> `settings.floor_plan`, and changes nothing that's already there. Kitchen
> departments never send those columns, so they keep working either way; a
> warehouse department shows "the database needs updating" until it's run.

### Storage zones —Dry / Chiller / Freezer

A zone belongs to a **rack**, because a rack stands in one room: an item is in
whichever zone its rack is in, so moving a product to a freezer rack makes it
freezer stock with nothing else to update. Set a rack's zone with ⚙ on the
Racks page (or a `Zone` column in the item sheet). Stock, Stocktake and Count
all filter by zone, and the Shelves view has a tab per zone.

### Cartons and packets

Each product has a **pack size** —packets per carton (1 = no cartons). Its
balance, minimum and every movement are then kept in packets, the smallest
unit it's handled in, and shown as `12 ctn 5 pkt`. Every place a quantity is
entered (Receive, Issue, Count, the Racks panel, Correct the count) takes
cartons and packets separately and adds them up, so breaking a carton open
needs nothing special.

- The unit names come from the YonYou UOM: `10x1kg/ctn` → 10 pkt per ctn,
  `100pcsx10roll/ctn` → 10 rolls, `5ltr/drum` → drums, `15kg/ctn` → the carton
  is the unit (nothing to split it into).
- **Set pack sizes from the UOM** (Stock page banner, or Setup) gives every
  product without a pack size the one its UOM spells out, in one go, with a
  preview. Items from before pack sizes existed were counted in the UOM's unit
  (cartons for a carton UOM) plus a separate Loose Qty; converting rescales the
  balance, minimum and past movements into packets and folds Loose Qty in, so
  history and totals stay right. Setting a pack size by hand in **Edit** does
  the same, asking once whether the old figures were cartons or packets.
- Until a product has a pack size it behaves exactly as before (one number,
  plus Loose Qty).

### Racks —floor plan

The Racks page opens on a drawn **floor plan**: the building's walls and
doors, the chiller and freezer rooms, the no-access areas, R1A–R9A where they
stand, the area outside the main door, and CENTER on the 2nd floor (floor
tabs). **Draw the 0434 floor plan** sets it all up in one click; nothing on any
rack changes.

- Each rack is drawn as a shelving unit with one band per level (1L, 2L, …),
  coloured by what's on that level: **white** fine, **amber** something below
  its minimum, **red** something out, dashed empty. A badge on the corner counts
  problems, so a bad shelf shows from across the map.
- **Tap a rack** (or the chiller / freezer / CENTER) to open its panel: every
  level, every product with its rack code, and **− / +** steppers for cartons
  and packets (or type). Changes stay a **draft** —highlighted, with "was … +2
  ctn"— until **Save changes**, which logs them together as one count
  (**Undo** puts the whole save back). Leaving the page with unsaved changes
  warns first. **+ Add product** on a level opens Add item with the next free
  rack code filled in.
- **Search** lists matching products by rack code; tapping one opens its rack
  with the product highlighted, and the map dims every rack without a match.
- **Edit layout** moves things to match the floor: drag a rack/wall/door/area
  to move it, drag its corner square to resize, or type exact numbers in the
  side panel. Racks not on the plan yet are listed there with **Place**. Rack
  positions are saved on the rack (`racks.x/y/w/h/floor`); walls, doors,
  no-access blocks and areas in `settings.floor_plan`.

### Racks —shelves view, and rack codes

The **Shelves** view is the drag-and-drop board: **Rack → Level → Position**,
matching the shelf labels `R1A | 1L | 01` = rack code `R1A1L01` (rack `R1A`,
level `1`, position `01`) —one per product. A rack is `items.store`, its level
`items.level`, its position `items.slot`.

- On a labelled rack (`R1A`, `R10B`, …) a product's position **is** its rack
  code, so nothing is renumbered: empty positions show as gaps, dropping a card
  on an empty spot puts it there, and dropping it on another product asks
  before **swapping** the two. Open areas like CENTER, the chiller and the
  freezer are plain ordered lists.
- Two products on the same rack code, or a product on a labelled rack with no
  position, are flagged in red at the top of the board.
- Moving a product into a different zone asks first.
- Typing a rack code in **Edit** (`R1A1L03`, also accepted as `R1A | 1L | 03`)
  places it there, refusing a code another product already has.
- Cards have ctn / pkt boxes; a change is logged as a correction.
- Racks start collapsed —click one to open it. Open/closed state, zone tab and
  plan/shelves choice are per-browser preferences (`localStorage`).

### Receive Stock

Stock arriving. Drop YonYou's purchase export (**PI_Item**: `MATCODE`,
`MATERIAL`, `SUPNAME`, `INVOICEDATE`, `COMP`, `BILLNO`, … `TOTALSQTY`,
`SUOM`), or key a delivery in by hand.

- The export covers every warehouse and has no warehouse column, so a line is
  taken in only if its `MATCODE` is on **this** warehouse's item list; the
  rest (other warehouses, services, consumables) are skipped and counted, with
  **Show them** to map one by hand if needed. A **Bought by** filter narrows
  the file to one company (`COMP`).
- Quantities come from `TOTALSQTY` in the stock unit `SUOM` —when that's the
  product's carton UOM (`12x0.4kg/ctn`) it's converted to packets; each line
  shows ctn/pkt and can be switched.
- Rows that leave `MATCODE` blank belong to the product above (the export
  only names it once); 小计 / 合计 subtotal rows are skipped.
- Every line is remembered by `BILLNO` + product: importing the same file again
  adds nothing, and a revised bill adds only the difference. The preview shows
  where each product is put away.
- Keying a delivery by hand with a document number that's already been
  received for that product asks first. Receipts can be deleted with a
  reason (reverses the balance and logs a correction), like issues.

### Issue Stock / Issued Summary

**Issue Stock** records stock leaving for another company (Quan Feng Food
Supply, Vaner Food Supply, …) in cartons + packets, showing the balance and
rack code of the product picked. **Issued Summary** totals it per company over a
date range, with a by-item breakdown and CSV export. Issues also count as
**usage**, so Use/day, Cover, trends and **Set minimums** work for a warehouse
the way sales do for a kitchen.

### Stocktake / Count

In a warehouse both are in **shelf order** —zone, rack as laid out, level,
position— grouped under zone + rack headings, with a zone filter. Counts are
keyed as cartons and packets in separate boxes. The printed sheets (Stocktake
paper and Count sheet) put **each zone on its own page** with Rack code,
System, Ctn and Pkt columns, so the freezer page can go to whoever is counting
the freezer.

### Item list import (warehouse)

**Setup → Item list import** reads `Rack Position`, `Zone`, `Product Code`,
`Product Name`, `UOM`, `Pkts per Ctn`, `Ctn Qty` (or `Physical Qty`),
`Loose Pkt Qty` (or `Loose Qty`), `Min (pkt)`, `Category`. Blank cells leave
what's there alone, so **Download current list (to edit)** → fill in pack sizes
/ zones / counts in Excel → drop it back in. A changed balance is logged and
can be undone. A rack position like `R8A1L01` is split into rack/level/position
automatically; anything else (`CENTER`, `CHILLER`) becomes an open area. New
racks are added to the board automatically. **Download rack template** gives a
blank sheet with the same columns.

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
- A sale's `tx` row carries an optional `amount` (revenue for that line), captured
  from a sales import only when the file has a recognisable total/amount column
  (TOTALAMT / AMOUNT / 金额 — a per-unit price column is deliberately not picked up,
  since it would need multiplying by quantity first rather than summed as-is).
  Rows imported before this existed, or from a file with no such column, just have
  `amount = null` — the **Sales** station (station 07) still counts their units
  normally and says plainly when a period's revenue total is partial. Revenue is
  scoped to the department you're in, same as everything else; it isn't rolled up
  across departments.

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
  eight tables should be listed, including `racks` and `levels`).
- **A department created before this version has no `amount` on old `tx` rows**:
  expected, not a bug — re-running `supabase-schema.sql` adds the column with
  `alter table ... add column if not exists`, but it can't retroactively know the
  revenue on sales imported before the column existed.

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

### Language —English / 简体中文

The **中文 / EN** button in the top bar switches the app between English and
Simplified Chinese. Each browser remembers its own choice, so one person
reading Chinese doesn't change it for anyone else.

- **What changes:** the interface text — buttons, headings, labels, messages
  and dialogs, plus the printed sheets and the stocktake report. Dates read
  10月14日, and units read 箱 / 包 / 瓶 / 罐 / 桶.
- **What stays as typed:** product names, codes, UOMs, rack codes, companies,
  suppliers and categories. These are your data, not part of the interface.
- **Downloaded Excel / CSV files:** their column headings stay in English, so
  a downloaded list can still be imported back in.

How it works: the app is written in English, and `ZH_DICT` in `index.html`
maps each interface phrase to its Chinese. Numbers and dates are matched as
placeholders, so `Apply {n} counts` covers every count. A phrase that isn't in
the dictionary simply stays in English. To add or fix a translation, edit its
entry in `ZH_DICT`.

### On a phone or tablet

Every page fits the screen width, with no sideways scrolling:

- **Station tabs:** the stations become a row of tabs across the top. Swipe the
  row sideways to reach the rest; it stays pinned while you scroll.
- **Tables:** below 760px wide, each table row is shown as a card. The product
  is on top, then each column as a label and value, with the row's buttons
  along the bottom.
- **Page descriptions:** long ones fold to three lines, with **More** to open
  them.
- **Dialogs:** they slide up from the bottom, with Cancel / Save always in
  reach.
- **Count:** the Apply button stays on screen while you count.
- **Racks floor plan:**
  - The whole floor fits the screen. **Zoom in** makes it bigger, and you
    scroll it inside its box.
  - Tapping a rack scrolls down to its panel, and **↑ Map** goes back up.
  - **Save changes** stays at the bottom of the screen until you press it.
- **Shelves view:** dragging cards may not work on every phone. If it doesn't,
  change a product's rack code with **Edit**.

## Warehouse departments (0434)

A department can be `kitchen` (the cook-line pages: Panel/Cook/Sales In/Sales)
or `warehouse` (Low Stock / Racks / Receive Stock / Issue Stock / Issued Summary
instead).
Setup → Departments has a Type selector when adding a new one. Stock,
Stocktake, Count, Log and Setup are shared by both types.

> **Updating an existing database:** re-run `supabase-schema.sql` *before*
> opening this version on a warehouse department. It adds `items.pack_size`,
> `items.unit`, `items.ordered_on`,
> `tx.supplier` / `tx.ref`, `racks.zone` / `x` / `y` / `w` / `h` / `floor` and
> `settings.floor_plan`, and changes nothing that's already there. Kitchen
> departments never send those columns, so they keep working either way; a
> warehouse department shows "the database needs updating" until it's run.

### Minimums and low-stock alerts

Every product has a **minimum** —the level below which it needs reordering—
without anyone having to type one in:

- **Auto** (the default): worked out from everything that goes out —issues,
  and sales once they're imported— as enough stock for N days of usage (N set
  in **Minimums** / Setup → Stock alert settings; delivery time plus a safety
  margin). While history is short it's average usage × N (falling back to the
  item's baseline usage per day); once there's about 4×N days on record it
  becomes the 90th percentile of rolling N-day demand, so a bad week is still
  covered. It's recalculated continuously as history builds.
- **Manual**: a number you set; it stays exactly as set.
- Each product has an **Auto | Manual** pill (Stock page, Low Stock page and
  Edit) with an **ⓘ** that explains it. Switching to Manual starts from what
  Auto would give, so nothing jumps. **Bought to order** (in Edit) means no
  minimum and no alerts. Storage: `items.min` > 0 is a manual minimum, 0 is
  Auto, the pre-order flag is "bought to order".

**Low Stock** (station 01, where a warehouse opens) lists what needs
reordering, worst first —out of stock, then below minimum by days left— with
the rack code, balance, minimum, days left, a **suggested order** (back to
about twice the minimum, rounded up to whole cartons), when and from whom it
was last received, and **Mark ordered** (`items.ordered_on`, cleared
automatically when a delivery for it is received). Below that: what will drop
below its minimum within a few days at the current rate, and products with no
minimum yet (no usage, no manual minimum). **Print reorder list** groups it by
the supplier each product last came from; **Export CSV** has the same.

**Alerts:** whenever a product crosses below its minimum or runs out —from an
issue keyed here, a count, an import, or a change made on another device
(it arrives live)— a banner drops in across the top of every page until it's
looked at. Once a day, opening the app shows how many products are low. The
OUT / BELOW MIN lamps in the top bar go to Low Stock, and the Low Stock entry
in the menu shows a red dot while anything is low. **Turn on desktop alerts**
(per device) also pops up a system notification when the app isn't the
window in front.

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
- **What's inside a carton** (`items.unit`) names the small unit when the UOM
  doesn't: a `24x0.4kg/ctn` of cans shows `2 ctn 5 can`, a `4x5ltr/ctn` of
  drums `1 ctn 3 drum`. It's learned automatically from YonYou's `PUOM` when a
  receipt is imported (bought by the can / btl / drum / tin …), read from a
  `Pkt Unit` column on the item sheet, or set in **Edit**. UOMs that name the
  unit themselves (`5ltr/drum`, `4ltr/btl`, `0.4kg/can`, `net17kg/tin`) need
  nothing.
- The balance is one pool of packets, shown as whole cartons + the rest: with
  5 pkt to a carton, 1 sealed carton + 6 loose counts as 11 pkt and shows as
  `2 ctn 1 pkt`. Taking out 8 pkt leaves `3 pkt` —a carton is opened
  automatically. Taking out more than there is takes the balance negative
  (shown red as Out, with a "recount it" warning) rather than refusing,
  because the invoice has already happened.

Dialogs (Add item, Edit, rack settings, confirmations …) close only from their
own buttons —Cancel, Save and so on— never from a tap outside or the Escape
key, so a half-filled form can't be lost by accident. **Category** is optional:
leave it blank and nothing shows; the category filter on the Stock page only
appears once a product has one.

### Racks —floor plan

The Racks page opens on a drawn **floor plan**, one tab per floor:

- **1st floor:** the building's walls and doors, the chiller and freezer
  rooms with their entrances, the no-access areas, R1A–R9A where they stand,
  and the area outside the main door.
- **2nd floor:** the stairwell in the top-left corner, R1B along the top, R2B
  beside the stairs, CENTER (dry storage) in the middle, R5B down the right
  wall, and R3B / R4B along the bottom-left.

**Draw the 0434 floor plan** sets up both floors in one click; nothing on any
rack changes. In **Edit layout**, **Redraw this floor from the 0434 plan**
resets just the floor you're on (useful if the plan was drawn before that
floor's layout was added) and leaves the other floor as it is.

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
- **Edit layout** moves things to match the floor: drag a rack/wall/door/
  stairs/area to move it, drag its corner square to resize, or type exact
  numbers in the side panel. Racks not on the plan yet are listed there with **Place**. Rack
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
- **Inserting a missed product.** On a labelled rack, both the floor-plan panel
  and the Shelves view have a **＋ insert** between neighbouring products
  (and before 01).
  - Tapping the one between 02 and 03 opens **Add item** with `…L03` filled in.
    The form says which products move.
  - On save, the new product takes 03. The product at 03 and the unbroken run
    after it each move up one, stopping at the first empty position, so as few
    shelf labels as possible change.
  - If there's already an empty spot between the two products, the new product
    just takes it and nothing moves.
  - Afterwards a dialog lists the shelf labels that changed. **Print list** gives
    a sheet for relabelling, and **Undo insert** puts every code back.
  - Changing the rack code in the form makes it a normal add, with no shifting.
  - In the Shelves view, an **empty** spot can also be tapped to add a product
    there.
  - Stock, history and product codes belong to the product, not the position,
    so nothing else is affected.
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

### Stocktake report

After a count on any page (Racks floor plan, Count, ± Count), go to
**Setup → Stocktake report**. The **Stocktake report** button on the Stocktake
page also goes there. The report lists every product's balance as it stands
now, in shelf order, zone by zone.

- **Count started:** pick the first day of the count. It defaults to the last
  day a count was saved. **Count change** for each product is the total of the
  corrections logged since that date. A product that was checked and already
  matched logs nothing, so it shows no change.
- **Zone:** report on all zones or just one.
- **Print report:**
  - The cover page has the totals: products, changed by the count, out of
    stock and below minimum. It also has a per-zone table (with cartons and
    loose units) and Counted by / Checked by / Approved by lines.
  - Then there is one page per zone. Each lists Rack code, Item, Balance
    (ctn + pkt), Total in packets, Count change and Status (OK / Low / Out).
  - Use **Print / Save PDF** to keep a copy.
- **Download Excel:**
  - A **Stocktake** sheet with one row per product: Zone, Rack Code, Product
    Code, Name, UOM, Pkts per Ctn, Ctn, Loose Pkt, Total (pkt), Count change,
    Last count change, Min and Status.
  - A **Summary** sheet with the totals per zone.

### Item list import (warehouse)

**Setup → Item list import** reads `Rack Position`, `Zone`, `Product Code`,
`Product Name`, `UOM`, `Pkts per Ctn`, `Ctn Qty` (or `Physical Qty`),
`Loose Pkt Qty` (or `Loose Qty`), `Min (pkt)`, `Category`. Blank cells leave
what's there alone, so **Download current list (to edit)** → fill in pack sizes
/ zones / counts in Excel → drop it back in. A changed balance is logged and
can be undone. A rack position like `R8A1L01` is split into rack/level/position
automatically; anything else (`CENTER`, `CHILLER`) becomes an open area.
A sheet typed **without a header row** —rack code | product code | name | UOM,
in any order— is read too: its columns are recognised by what's in them, and
a product row is never mistaken for headings. A new product with no
`Pkts per Ctn` takes its pack size from its UOM. New
racks are added to the board automatically. **Download rack template** gives a
blank sheet with the same columns.

## Notes on the data model

- Each **department** (e.g. `0428`, `0227`) has its own items, movement log, cook
  plan, invoice registry and settings — exactly like the original design's
  Firestore subcollections, just as Postgres rows scoped by a `dept_id` column.
- Item, movement-log, cook-plan and batch IDs are assigned on the device, not by
  Postgres identity columns. That lets every action (adding an item, logging a
  cook, importing sales) update the screen immediately without waiting on a round
  trip; a background sync then pushes only the rows that changed.
  - **Unique across devices:** each ID is the time in milliseconds × 1000 plus a
    random 0–999. Two phones that haven't heard from each other yet can't pick the
    same number, so one can't overwrite the other's product or log entry. An
    earlier version took "the next number" from a shared counter, and that did
    happen.
  - **Size:** IDs stay under 2^53, so they're exact in JavaScript and in `bigint`.
  - **Composite primary key:** `items`/`tx`/`plan` keep the `(dept_id, id)` key.
- **Saving only what changed:** a product that's already on the server sends only
  the columns that changed. A count sends the balance, not an old copy of the
  rack, the "ordered" mark or the name. Settings likewise send only the fields
  that changed.
- Removing a department (Setup → Departments) is a real, permanent delete —
  Postgres cascades and removes its items, log, plan and settings. The original
  Firestore version only removed it from the switcher; this one is unforgiving,
  matching how a real relational schema behaves. Export a backup first.
- **Copy on the device:** the current department's data is mirrored into
  `localStorage`, so the page shows the last-seen numbers straight away and if
  the connection drops. Supabase is the source of truth once reachable.
- **Unsaved changes are never thrown away:** anything changed on a device that
  the server hasn't confirmed yet is also kept in `localStorage`. This covers a
  product added while the app is still loading, a save that failed for lack of
  signal, and the app closed before the save went through.
  - When fresh server data arrives (another device saved, the app reopened, the
    connection came back), the page is rebuilt from it and those changes are put
    back on top, field by field. Then they're sent again.
  - After a successful save, the device updates its own copy straight away
    instead of waiting for the live update to echo back.
- **Live on every device:** each save reaches every open device through
  Supabase Realtime, usually within a second.
  - **Catching up:** coming back to the app after 30+ seconds, or the connection
    returning, re-reads everything.
  - **Fallback:** every save is expected to come straight back to the device
    that made it. If it doesn't within a few seconds, live updates aren't getting
    through to that device, so it reads the server every 20 seconds until they
    do.
  - **Status:** the top bar shows **live · all devices** or **every 20 s**.
- **Undo is per device:** it reverses only what that device last did, never
  another device's action.
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

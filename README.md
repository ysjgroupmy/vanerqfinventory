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
or `warehouse` (Low Stock / Racks / Receive Stock / Issue Stock / Sales
Deduction / Issued Summary instead). A warehouse numbers its stations on from
Sales Deduction (10): Issued Summary 11, Log 12, Setup 13. A kitchen keeps Log
11 and Setup 12.
Setup → Departments has a Type selector when adding a new one. Stock,
Stocktake, Count, Log and Setup are shared by both types.

> **Updating an existing database:** re-run `supabase-schema.sql` *before*
> opening this version on a warehouse department. It adds `items.pack_size`,
> `items.unit`, `items.ordered_on`,
> `tx.supplier` / `tx.ref`, `racks.zone` / `x` / `y` / `w` / `h` / `floor`,
> `settings.floor_plan` and `bills.info`, and changes nothing that's already
> there. Kitchen
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

### Minimums never below one order (kitchens and 0434)

Some products go out rarely but in one go: a customer takes 5 packets once a
month. Their use per day averages almost nothing, so 3 in stock reads as
weeks of cover. A percentile minimum comes out 0, and the next order takes the
balance negative with no warning.

**One order** is the most that's gone out in a single day over the last 6
months. With 4 or more orders, a day more than 3× the usual size is left out,
so one freak bulk order doesn't set it.

- **Kitchens:** the minimum in use is the larger of the product's minimum and
  one order. It drives the status (Below min), the Panel's make list, the stock
  against minimum bars and the printed cook sheet.
  - The Stock page's Min column shows it with ↑ when it's been raised. Hover
    for the order size.
  - **Set minimums** gives the same.
- **Warehouse:** automatic minimums are never below one issue or sale either.
  A manual minimum stays exactly as typed.
- **Cover:** when the balance can't cover one order, the Cover column says
  **< 1 order** instead of a number of days. The cook sheet files the product
  under THIS WEEK, showing 不够 1 单.
- **Pre-order** (made to order) products still have no minimum and never
  alert. A rarely sold product you do keep in stock should not be Pre-order.

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
  - The sales bills remembered for the product are rescaled too. Importing the
    same sales file again then compares like with like, and puts right a sale
    that was counted in the wrong unit.
- **A pack size of 1 on a UOM that holds more** (`24x0.397kg/ctn` with pack
  size 1) keeps the balance in whole cartons, so one can sold or issued would
  come off as a carton.
  - The Stock page lists these products.
  - **Set pack sizes from the UOM** and **Edit** convert them: 4 ctn becomes
    96 cans, not 4.
- **Add item:** the pack size fills in from the UOM as you type it
  (`24x0.397kg/ctn` → 24), until you change it by hand.
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
key, so a half-filled form can't be lost by accident.

**Enter** in a dialog's box presses its main button. For example, type a
product name in **Add item** and press Enter to add it, or press Enter in
**Edit** to save.
- It never presses a red, deleting button.
- It doesn't fire while a Chinese input method is still composing characters.

**Category** is optional:
leave it blank and nothing shows; the category filter on the Stock page only
appears once a product has one.

### Racks —floor plan

The Racks page opens on a drawn **floor plan**, one tab per floor:

- **1st floor:** the building's walls and doors; the chiller and freezer
  rooms with their entrances; R1A–R9A where they stand; and the area outside
  the main door.
  - The chiller runs across to the right-hand wall, and the freezer below it
    is the same width.
  - Each was first drawn narrower, beside a hatched no-access block. A saved
    plan still in that first shape is enlarged once, automatically, by
    whichever device opens it first. A layout edited by hand is left alone.
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
- **Edit / Delete:** every product on the floor-plan panel has **Edit** and
  **Delete** buttons, and every Shelves card has **✎** / **✕**. Delete asks
  first. The movement history stays in the log.
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
Supply, Vaner Food Supply, …) in cartons + packets.

- **Several products in one issue:** the company, date and note are filled in
  once, then one line per product. **＋ Add another item** adds a line.
- **Enter key:** on a product box, Enter moves to its quantity. On the last
  quantity, Enter starts a new line.
- **Under each line:** the balance now and after this issue, its rack code, and
  how many packets make a carton. If the same product is on two lines, both are
  counted. A balance that would go below zero shows in red.
- **Issue N items:** issues every line at once.
  - Blank lines are skipped.
  - A line with a product but no quantity (or the other way round) stops the
    issue and is marked, so nothing goes out half-entered.
- **Each product is still its own line under Recent issues,** so one line can be
  deleted on its own (with a reason, as before).

**Issued Summary** totals it per company over a
date range, with a by-item breakdown and CSV export. Issues also count as
**usage**, so Use/day, Cover, trends and **Set minimums** work for a warehouse
the way sales do for a kitchen.

### Sales Deduction

Takes what was sold off the stock on hand. Drop YonYou's sales export
(**SI_Item**: `INVOICEDATE`, `BILLTYPENAME`, `COMP`, `BILLNO`, … `MATCODE`,
`MATERIAL`, `UOM`, `TOTALQTY`).

- **Bill protection, always on:** every line is remembered by `BILLNO` +
  product, in the same bill registry the kitchen's sales import uses.
  - Importing the same file again, or one that overlaps, takes nothing off
    twice.
  - A bill edited in YonYou since applies only the difference.
  - A file without a bill number column is refused.
- **Only this warehouse's products:** the export covers both companies and every
  warehouse. A line is taken off only if its `MATCODE` is on **this**
  warehouse's item list; the rest are skipped and counted, with **Show them**
  to map one by hand.
  - **Sold by:** ticks for each company (`COMP`) narrow the file to the
    companies whose sales come out of this warehouse.
- **Units:** `UOM` is what was sold.
  - A single can (`0.425kg/can`) of a product stocked by the carton
    (`24x0.425kg/ctn`) is one can, and the carton UOM is 24 of them.
  - Sizes decide, not the word on the UOM. Fine Salt Box is stocked
    `48x0.5kg/ctn` and sold `0.5kg/box`; the box is the 0.5 kg unit inside the
    carton, so one box is one unit. Only the item's own carton UOM, a UOM that
    says how many it holds, or the whole carton's size (`10kg/ctn` of
    `10x1kg/ctn`) counts as a carton. Receiving follows the same rule.
  - The item's own UOM counts as a carton only if it actually is one
    (`24x0.397kg/ctn`, `15kg/ctn`). A product stocked as `0.397kg/can`, 24 to
    a carton, sold as `0.397kg/can` is one can.
  - **Corrections:** a bill whose quantity changed is corrected the way it was
    first applied. One recorded for trends only stays trends only; one taken
    off stock gets the difference taken off or put back. So importing the same
    file again puts right sales that an earlier version counted wrongly.
  - **Count as** shows the choice for each product and can be switched.
  - A product sold in a different pack size from the one stocked (sold
    `0.1kg/pkt`, stocked `0.5kg/pkt`) isn't taken off until someone picks how
    to count it.
  - **Kept in whole cartons:** a single can or packet of a product whose
    balance is in whole cartons isn't taken off. That means no pack size, or a
    pack size of 1 on a UOM like `24x0.397kg/ctn`. The preview names it: give
    it a pack size, then import the file again. A whole carton sold still
    comes off.
- **Subtotals and returns:** 分节小计 subtotal rows (they carry the product
  code and its total for the whole file) are skipped. 退换货 return lines have a
  negative quantity and put stock back.
- **Trends only:** records the sales (usage, trends, Set minimums) and remembers
  the bills, without changing any balance.
- **First import:** the first file usually reaches back months, long before the
  stock was counted. So the first import starts on **Only sales from** the day
  after the last count: earlier sales are recorded for trends only, later ones
  come off. After that, every new bill comes off. The date can be changed or
  unticked.
  - Import the latest sales before a stocktake. A sale dated on or before a
    count but imported after it would otherwise come off twice.
- **Issue Stock overlap:** if **Issue Stock** has issues of the same products to
  the same company over the same days, the preview warns. An issue and a sale
  of the same goods would come off twice.
- **Sales on record:** lists what's been taken off. **Undo last import**
  reverses an import: balances, the bill registry and the log go back as they
  were.
- **The whole line is kept:** each bill + product also stores everything else
  on the line, as JSON text in `bills.info`. That's the customer and customer
  category, salesman, company, bill type, product type and category, UOM sold,
  net and highest unit price, YonYou's price-change flag, amount, GST,
  discount and total.
  - A bill imported before this was kept gets its detail when the same file is
    imported again. The preview offers **Add detail to N bills**, and the stock
    isn't touched.
  - Until `supabase-schema.sql` is re-run, `bills.info` doesn't exist. Imports
    still work and the stock still comes off, but the detail isn't saved, and
    the dashboards say so.

### Sales dashboards

Built from the imported sales.

- **Time range:** Today, Yesterday, 7 / 30 / 90 days (calendar days ending
  today), All (every sale on record), or **Custom**: two dates picked on the
  calendar.
  - **Not imported yet:** sales come in batches, so a range can run past the
    newest sale imported. The dashboard then says "Sales imported up to …", and
    per-day figures only count the days imported so far.
  - **A single day** (Today, Yesterday) shows the figures, breakdowns and
    bills without a one-column chart.
- **Table** shows the same numbers as a table.

- **Stock → Sales** (a button on every product in a warehouse) shows one product:
  - **Headline figures:** sold, per day, busiest day, days with sales, revenue
    (excl GST, with GST and the GST itself), average price per unit and the
    latest invoiced price, customers and bills, discount given, and returns and
    price changes.
  - **Charts:** units sold each day (with the average), and the price per unit
    each day against YonYou's highest price.
  - **Breakdowns:** customers (with their category), customer categories,
    salesmen and companies.
  - **Bills:** each bill with customer, salesman, qty, price, amount, and tags
    for returns, price changes and discounts.
- **Sales Deduction → Sales dashboard** shows the whole warehouse:
  - **Headline figures:** revenue (with GST), bills and the average bill,
    customers and categories, products sold, revenue per day, discount given,
    returns, and bills flagged for a price change.
  - **Revenue each day.**
  - **Breakdowns:** products (tap one for its own dashboard), customers,
    customer categories, salesmen, companies, product categories and product
    types.
  - **Prices that moved:** first and latest price on the same UOM, the change
    and the range.

### Shared stock with the kitchens (0428, 0227)

The kitchens keep their finished products in 0434's chiller, freezer and
CENTER, so those products have **one balance** on both sides.

- **Which products:** a kitchen product whose **Storage location** has
  `0434` in it and names one of 0434's rooms, or is CENTER (0434's
  2nd-floor dried-goods area, `0434` optional).
  - Chiller: `CH`, `Chiller`, `Chilled`, 冷藏.
  - Freezer: `FR`, `FZ`, `Freezer`, `Frozen`, 冷冻.
  - CENTER: `Center`, `Centre`, `CTR`.
  - Examples: `0434CH`, `0434 Freezer`, `FR 0434`, `0434 CENTER`. Spaces,
    dashes and capitals don't matter, and a number after the room is fine
    (`0434FR2`).
  - **A chiller or freezer without `0434` isn't 0434's,** so it isn't shared.
    That covers plain `Freezer`, another site's freezer (`0424FR`), and the
    kitchen's own (`0428 FR`). A kitchen's Shared stock check lists these
    under **All**: "no 0434 in its location". CENTER with another code
    (`0424 CENTER`) isn't 0434's either.
  - A product 0434 added for a kitchen product whose location no longer
    points to 0434 is removed again when 0434 opens. That only happens if
    0434 never counted, issued, received or sold it itself. Otherwise it's
    kept and listed on Setup.
- **Matched by code and unit size:** `2kg/pkt` and `0.2kg/pkt` of the same
  code are separate products. 0434 can hold it as `2kg/pkt`, or as a carton
  (`6x2kg/ctn`) with a pack size, because then its balance is in packets
  too.
  - A product 0434 keeps in whole cartons can't share yet: no pack size, or a
    pack size of 1 on a carton UOM like `8x3kg/ctn`. Its balance isn't in the
    kitchen's unit. Give it its pack size (Stock → Set pack sizes from the UOM)
    and it links.
- **Shared stock check** (Setup, kitchens and 0434) lists every product that
  should be shared, with both balances. Under **Needs attention** it shows why
  one isn't shared yet:
  - 0434 keeps it in whole cartons.
  - It isn't in 0434 yet.
  - Its location mentions 0434 but names no room.
  - On 0434's side, it also lists the products in its chiller, freezer and
    CENTER that no kitchen product matches.
- **Products 0434 doesn't have yet** are added to the room the kitchen names,
  with the kitchen's balance.
  - In 0434 that room is the rack set to Chiller or Freezer, or named for it
    (`0434CH`, `0434FR`, `CHILLER`, `FREEZER`), or `CENTER`. The one drawn on
    the floor plan comes first.
  - A rack named for the chiller or freezer that still says Dry is set to
    Chiller / Freezer, so its products show there.
  - A shared product 0434 has with no rack yet, or on a chiller or freezer rack
    that isn't drawn while the drawn one exists, is put in the drawn room.
  - Products made to order (Pre-order) or stopped with nothing in stock wait
    until there is some.
- **When they're first linked**, a product 0434 already had takes the
  kitchen's balance. 0434's log notes it: "0428 · shared from now on".
- **After that, any change on either side changes both.**
  - This covers a cook, the kitchen's sales import, a count, a receipt, an
    issue or an Undo.
  - Each side's log shows the other side's changes as **Shared**, for
    example "0428 · Cook" or "0434 · Count · Rack count".
  - The Log page's filter has **Shared stock** to list only these.
  - 0434's Stock page and rack panel tag these products **Shared** with the
    kitchen, for example "Shared 0428". A kitchen's Stock page doesn't tag
    them, so it looks the way it did before sharing.
- **Sales come off once, on the kitchen side.**
  - The kitchen's Sales import takes them off.
  - 0434's Sales Deduction records them for the graphs only, and its preview
    says so.
  - Don't also **Receive** the kitchens' products into 0434: the kitchen's
    Cook already adds them.
- **No signal:**
  - A change for the other side is kept on the phone that made it and sent
    when the connection is back, as with any other save.
  - A change made before the app knew which products are shared (still
    opening, or no signal) is sent once it does.
- Two products in both kitchens with the same code and size (for example the
  same soup in 0428 and 0227) share one balance between all three.

Nothing to run in Supabase for this.

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
- **Big imports are saved in batches:** a sales export can add thousands of
  bills and log rows. They go to the server a few hundred rows per request, and
  deletes (an Undo of such an import) name at most 150 keys per request. A
  delete lists its keys in the URL, and that has a length limit.
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

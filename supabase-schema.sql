-- ============================================================
-- 0428 Sauce Line — Supabase schema
-- Run this in your project's SQL editor (Supabase Dashboard → SQL Editor →
-- New query → paste → Run). Safe to re-run any time this file changes —
-- every statement either checks first or uses "if not exists" —so picking
-- up a schema update on a database that already ran an earlier version of
-- this file just adds what's new and leaves existing data untouched.
--
-- Auth model: Clerk handles sign-in; Supabase is configured to trust
-- Clerk-issued JWTs via Third-Party Auth (see README.md). Once that is
-- wired up, any request carrying a valid Clerk session token is treated
-- by Postgres as the built-in `authenticated` role, which is what the
-- policies below check for. There is no per-row ownership — every
-- signed-in user can read and write every department's data, matching
-- the original "one shared line, several devices" behaviour. If you
-- want to restrict who can sign in, do that in Clerk (disable public
-- sign-up, use an allowlist/invite flow), not here.
-- ============================================================

create table if not exists departments (
  id          text primary key,          -- department code, e.g. "0428"
  code        text not null,
  name        text not null default '',
  company     text not null default '',
  sort_order  int  not null default 0,
  type        text not null default 'kitchen'   -- 'kitchen' (cook line) | 'warehouse' (racks/stock)
);
alter table departments add column if not exists type text not null default 'kitchen';

-- id is assigned client-side by a per-department counter (state.nextId), so
-- item #1 in department "0428" and item #1 in department "0227" are
-- different rows — the primary key must include dept_id or they'd collide.
create table if not exists items (
  id          bigint not null,           -- client-assigned (state.nextId)
  dept_id     text not null references departments(id) on delete cascade,
  name        text not null,
  uom         text not null default '',
  code        text not null default '',
  store       text not null default '',
  cat         text not null default 'Uncategorised',
  stock       numeric not null default 0,
  min         numeric not null default 0,
  base_daily  numeric not null default 0,
  preorder    boolean not null default false,
  stopped     boolean not null default false,
  watch       boolean not null default false,
  counted     boolean not null default false,
  updated_at  timestamptz not null default now(),
  loose_qty   numeric not null default 0,   -- warehouse depts: loose pieces beyond full units counted in `stock`
  level       text not null default '1',    -- warehouse depts: shelf level within its rack (store field)
  slot        int not null default 0,       -- warehouse depts: left-to-right position within rack+level
  primary key (dept_id, id)
);
alter table items add column if not exists loose_qty numeric not null default 0;
alter table items add column if not exists level text not null default '1';
alter table items add column if not exists slot int not null default 0;

create table if not exists tx (
  id          bigint not null,           -- client-assigned (state.txSeq), per department
  dept_id     text not null references departments(id) on delete cascade,
  ts          bigint not null,
  date        date not null,
  item_id     bigint,                    -- not FK-enforced: history survives item deletion
  type        text not null,             -- production | sale | adjust
  qty         numeric not null,
  note        text not null default '',
  batch       bigint,
  planned     numeric,
  hist        boolean not null default false,
  primary key (dept_id, id)
);
-- amount: revenue for this line, from an import's price/amount column; null if not
-- present or the row predates revenue capture. Added via alter so re-running this
-- file against an existing database (create table if not exists skips the table
-- entirely) still picks it up.
alter table tx add column if not exists amount numeric;
-- Warehouse depts: which outside company an 'issue' movement went to (Quan Feng
-- Food Supply, Vaner Food Supply, ...). Null for every other tx type.
alter table tx add column if not exists dest_company text;
create index if not exists tx_dept_date_idx on tx(dept_id, date);

create table if not exists plan (
  id          bigint not null,           -- client-assigned (state.planSeq), per department
  dept_id     text not null references departments(id) on delete cascade,
  date        date not null,
  item_id     bigint not null,
  qty         numeric not null,
  done        boolean not null default false,
  primary key (dept_id, id)
);

create table if not exists bills (
  dept_id     text not null references departments(id) on delete cascade,
  bill_key    text not null,             -- "<BillNo>§i<itemId>"
  qty         numeric not null,
  date        date,
  primary key (dept_id, bill_key)
);

create table if not exists settings (
  dept_id           text primary key references departments(id) on delete cascade,
  capacity          numeric not null default 600,
  cover_target      int not null default 7,
  prod_head         text not null default '',
  stocktake         jsonb not null default '[]',
  demo              boolean not null default false,
  next_id           bigint not null default 1,
  plan_seq          bigint not null default 1,
  batch_seq         bigint not null default 1,
  tx_seq            bigint not null default 1,
  last_batch        bigint,
  last_batch_bills  jsonb
);

-- Warehouse depts only: the set of racks/zones available to file items under,
-- so a rack can be created ahead of anything being placed in it. A product's
-- rack assignment itself lives on items.store (already a free-text location
-- field used the same way by kitchen departments) — this table just tracks
-- which rack names exist and their display order for the Racks board.
create table if not exists racks (
  dept_id     text not null references departments(id) on delete cascade,
  name        text not null,
  sort_order  int  not null default 0,
  row_no      int  not null default 1,   -- which physical row/floor this rack is laid out on
  primary key (dept_id, name)
);
alter table racks add column if not exists row_no int not null default 1;

-- Warehouse depts only: same idea as `racks`, one level below it —a level
-- that has ever existed (added by hand, or seen once on an imported row)
-- keeps its own row here so it stays on the board even after every item on
-- it is moved away or deleted. Not FK'd to racks.name (same loose coupling
-- items.store already has to racks —no cascade surprises if a rack row and
-- its levels are removed in separate steps).
create table if not exists levels (
  dept_id     text not null references departments(id) on delete cascade,
  rack        text not null,
  level       text not null,
  sort_order  int  not null default 0,
  primary key (dept_id, rack, level)
);

-- ---------- Row Level Security ----------
alter table departments enable row level security;
alter table items       enable row level security;
alter table tx          enable row level security;
alter table plan        enable row level security;
alter table bills       enable row level security;
alter table settings    enable row level security;
alter table racks       enable row level security;
alter table levels      enable row level security;

drop policy if exists "authenticated full access" on departments;
create policy "authenticated full access" on departments
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on items;
create policy "authenticated full access" on items
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on tx;
create policy "authenticated full access" on tx
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on plan;
create policy "authenticated full access" on plan
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on bills;
create policy "authenticated full access" on bills
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on settings;
create policy "authenticated full access" on settings
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on racks;
create policy "authenticated full access" on racks
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated full access" on levels;
create policy "authenticated full access" on levels
  for all to authenticated using (true) with check (true);

-- ---------- Realtime ----------
-- Lets every open browser tab see another tab's/device's changes live.
-- Added one table at a time, guarded by a membership check —"alter publication
-- ... add table" errors with "is already a member" if run again on a table
-- already added, which would otherwise make re-running this whole file (e.g.
-- after pulling in a schema update, on a database that already ran an earlier
-- version of it) fail outright instead of just skipping what's already there.
do $$
declare t text;
begin
  foreach t in array array['departments','items','tx','plan','bills','settings','racks','levels'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;

-- ---------- Seed the first department ----------
insert into departments (id, code, name, company, sort_order, type)
values ('0428', '0428', 'Sauce Production', 'Quan Feng Food Supply', 1, 'kitchen')
on conflict (id) do nothing;

insert into settings (dept_id) values ('0428')
on conflict (dept_id) do nothing;

-- ---------- Seed the 0434 warehouse department ----------
insert into departments (id, code, name, company, sort_order, type)
values ('0434', '0434', 'Vaner Trading Warehouse', 'Vaner Trading Pte Ltd', 2, 'warehouse')
on conflict (id) do nothing;

insert into settings (dept_id) values ('0434')
on conflict (dept_id) do nothing;

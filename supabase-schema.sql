-- ============================================================
-- 0428 Sauce Line — Supabase schema
-- Run this once in your project's SQL editor (Supabase Dashboard
-- → SQL Editor → New query → paste → Run).
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
  sort_order  int  not null default 0
);

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
  primary key (dept_id, id)
);

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

-- ---------- Row Level Security ----------
alter table departments enable row level security;
alter table items       enable row level security;
alter table tx          enable row level security;
alter table plan        enable row level security;
alter table bills       enable row level security;
alter table settings    enable row level security;

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

-- ---------- Realtime ----------
-- Lets every open browser tab see another tab's/device's changes live.
alter publication supabase_realtime add table departments, items, tx, plan, bills, settings;

-- ---------- Seed the first department ----------
insert into departments (id, code, name, company, sort_order)
values ('0428', '0428', 'Sauce Production', 'Quan Feng Food Supply', 1)
on conflict (id) do nothing;

insert into settings (dept_id) values ('0428')
on conflict (dept_id) do nothing;

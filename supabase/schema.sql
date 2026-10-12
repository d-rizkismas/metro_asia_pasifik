-- Kairos Project Management: shared workspace storage for Supabase
-- Run once in Supabase Dashboard > SQL Editor as project owner.
-- The app stores the current workspace payload as JSONB, while membership,
-- access control, and optimistic locking remain relational and server-enforced.

create extension if not exists pgcrypto;

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  owner_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','project_manager','team_member','stakeholder')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.workspace_state (
  workspace_id uuid primary key references public.workspaces(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  version bigint not null default 1 check (version > 0),
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

create index if not exists workspace_members_user_id_idx
  on public.workspace_members(user_id);

-- SECURITY DEFINER helpers avoid recursive RLS checks on workspace_members.
create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = target_workspace and wm.user_id = auth.uid()
  );
$$;

create or replace function public.is_workspace_owner(target_workspace uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspaces w
    where w.id = target_workspace and w.owner_id = auth.uid()
  ) or exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = target_workspace
      and wm.user_id = auth.uid()
      and wm.role = 'owner'
  );
$$;

create or replace function public.can_edit_workspace(target_workspace uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = target_workspace
      and wm.user_id = auth.uid()
      and wm.role in ('owner','project_manager','team_member')
  );
$$;

revoke all on function public.is_workspace_member(uuid) from public;
revoke all on function public.is_workspace_owner(uuid) from public;
revoke all on function public.can_edit_workspace(uuid) from public;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.is_workspace_owner(uuid) to authenticated;
grant execute on function public.can_edit_workspace(uuid) to authenticated;

-- Deny unauthenticated/public SQL access explicitly; only signed-in users
-- receive table privileges, and row-level policies further limit each row.
revoke all on public.workspaces, public.workspace_members, public.workspace_state from anon, public;
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.workspaces to authenticated;
grant select, insert, update, delete on public.workspace_members to authenticated;
grant select, insert, update, delete on public.workspace_state to authenticated;

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_state enable row level security;

-- Workspaces: members may read; only owner may create/manage workspace metadata.
drop policy if exists workspaces_select_member on public.workspaces;
create policy workspaces_select_member on public.workspaces
  for select to authenticated
  using (public.is_workspace_member(id) or owner_id = auth.uid());

drop policy if exists workspaces_insert_owner on public.workspaces;
create policy workspaces_insert_owner on public.workspaces
  for insert to authenticated
  with check (owner_id = auth.uid());

drop policy if exists workspaces_update_owner on public.workspaces;
create policy workspaces_update_owner on public.workspaces
  for update to authenticated
  using (public.is_workspace_owner(id))
  with check (public.is_workspace_owner(id));

drop policy if exists workspaces_delete_owner on public.workspaces;
create policy workspaces_delete_owner on public.workspaces
  for delete to authenticated
  using (public.is_workspace_owner(id));

-- Memberships: any member can see the roster; only workspace owners can change it.
drop policy if exists workspace_members_select_member on public.workspace_members;
create policy workspace_members_select_member on public.workspace_members
  for select to authenticated
  using (public.is_workspace_member(workspace_id) or public.is_workspace_owner(workspace_id));

drop policy if exists workspace_members_insert_owner on public.workspace_members;
create policy workspace_members_insert_owner on public.workspace_members
  for insert to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_members_update_owner on public.workspace_members;
create policy workspace_members_update_owner on public.workspace_members
  for update to authenticated
  using (public.is_workspace_owner(workspace_id))
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_members_delete_owner on public.workspace_members;
create policy workspace_members_delete_owner on public.workspace_members
  for delete to authenticated
  using (public.is_workspace_owner(workspace_id));

-- Shared project data: every member can read; owners, PMs, and team members can edit.
-- Stakeholders are read-only. The version filter in the app prevents silent
-- last-write-wins overwrites when two people edit at the same time.
drop policy if exists workspace_state_select_member on public.workspace_state;
create policy workspace_state_select_member on public.workspace_state
  for select to authenticated
  using (public.is_workspace_member(workspace_id) or public.is_workspace_owner(workspace_id));

drop policy if exists workspace_state_insert_owner on public.workspace_state;
create policy workspace_state_insert_owner on public.workspace_state
  for insert to authenticated
  with check (public.is_workspace_owner(workspace_id));

drop policy if exists workspace_state_update_editor on public.workspace_state;
create policy workspace_state_update_editor on public.workspace_state
  for update to authenticated
  using (public.can_edit_workspace(workspace_id))
  with check (public.can_edit_workspace(workspace_id));

drop policy if exists workspace_state_delete_owner on public.workspace_state;
create policy workspace_state_delete_owner on public.workspace_state
  for delete to authenticated
  using (public.is_workspace_owner(workspace_id));

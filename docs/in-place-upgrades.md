# In-Place Upgrade Guardrails

This scenario is upgraded in-place on live saves, so most code paths are written
to be safe when state is missing, partially initialized, or mid-migration. This
document describes the guardrails that make hot upgrades safe.

## Goals

- Never assume a new field exists in an old save.
- Avoid re-running expensive or destructive setup when not needed.
- Keep upgrades deterministic and resilient to partial reloads.

## Versioning and Setup Flow

`version.lua` contains the release string. `control.lua` loads it into
`storage.SM_Version` and drives setup:

- `script.on_init` and `script.on_configuration_changed` call `RunSetup()`.
- `RunSetup()` always performs safe initialization and only performs heavy work
  when the version changes.

Key details in `RunSetup()` (`control.lua`):

- `STORAGE_CreateGlobal()` creates/repairs global and per-player storage.
- `PERMS_EnsureGroups()`, `PERMS_ApplyStaticPermissions()`,
  `PERMS_SetPermissions()` keep permission groups and rules stable.
- Expensive, one-time tasks (jail surface, logo, map pin, friendly fire, replay
  disable, cloud removal) are guarded by `storage.SM_OldVersion ~= SM_VERSION`.

This means the scenario can be reloaded or upgraded without repeating heavy
operations.

## Persistent Storage Pattern

All persistent state lives in the global `storage` table. Initialization is
split between:

- `STORAGE_EnsureGlobal()` (creates `storage.SM_Store`, defaults, and flags).
- `STORAGE_MakePlayerStorage(player)` (per-player defaults).
- `STORAGE_CreateGlobal()` calls both and is safe to run repeatedly.

Whenever new fields are added, they must be initialized in `storage.lua` so
older saves pick them up automatically.

### LuaObject Storage

Some globals store LuaObjects (e.g., permission groups, chart tags). Always
check `.valid` before use, and recreate if missing. Helpers like
`PERMS_EnsureGroups()` and `UTIL_MapPin()` handle this.

## Permissions Guardrails

Permissions are rebuilt as needed in `perms.lua`:

- `PERMS_EnsureGroups()` creates missing groups and re-links them into storage.
- `storage.SM_Store.perms_static_applied` prevents reapplying static rules on
  every reload, but is reset if groups are recreated.
- `PERMS_ApplyStaticPermissions()` applies the static deny list once per group
  lifecycle.
- `PERMS_SetPermissions()` toggles the default group based on
  `storage.SM_Store.restrictNew`.

This avoids missing groups after upgrades while keeping expensive permission
sets from rerunning constantly.

## Online UI Refresh Guardrail

The online list is expensive to rebuild, so refreshes are throttled:

- `ONLINE_MarkDirty()` marks the list as stale.
- `ONLINE_UpdatePlayerList()` only runs on the 10-second tick if dirty.

When changing player state (banish, permission changes, one-life status), call
`ONLINE_MarkDirty()` rather than forcing a full update immediately.

## UI/Event Entry Safety

Most event handlers and UI entry points guard against missing data:

- Validate `event` and `event.player_index`.
- Validate `player`, `player.valid`, and the relevant GUI roots.
- Call `STORAGE_EnsureGlobal()` and `STORAGE_MakePlayerStorage()` in UI entry
  points that can be triggered after reloads.

This allows players to open/close windows safely even if the save is mid-upgrade.

## Factorio 2.0-Specific Guards

- `prototypes` is required for quality-aware inventory logic. If unavailable,
  functions like `UTIL_DumpInv()` and quickbar import abort rather than risking
  item loss.
- `player.physical_surface` is used when listing surfaces or teleporting to
  avoid controller/surface mismatches.
- When reviving spectators, `onelife.lua` avoids creating characters on
  `empty_void` surfaces and falls back to `game.surfaces[1]`.

## Command Registration Safety

Commands are registered via `CMD_RegisterCommands()` and use `CMD_AddCommand()`,
which removes any existing command before re-adding it. This prevents duplicate
command errors across hot reloads and allows safe upgrades without restarting
the save.

## Adding New Features Safely

When implementing new behavior:

- Initialize new fields in `storage.lua`.
- Use nil-safe access patterns and `.valid` checks for LuaObjects.
- Prefer idempotent setup functions so they can be called multiple times.
- Gate expensive or one-time actions behind version checks in `RunSetup()`.
- Use `ONLINE_MarkDirty()` for state changes that affect the online list.

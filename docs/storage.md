# Storage Table Overview

The mod uses a single global table named `storage` to keep persistent data for all systems.
This is required because Factorio scenario scripts have limited options for storing global
state.

`storage` has two main sections:

* `storage.SM_Store` – global mod settings and shared state.
* `storage.PData` – per-player data indexed by `player.index`.

Each system stores its values in these tables rather than creating additional globals.
The structure is created during on_init by `STORAGE_CreateGlobal()` and
`STORAGE_MakePlayerStorage()` in `storage.lua`.

When adding new fields, try to group them logically under these tables. For example,
`storage.SM_Store.votes` holds active vote-banish information and
`storage.PData[player.index].active` tracks whether a player was active this tick.
Keeping related values together helps avoid conflicts and makes saved data easier to
inspect.

Manual moderator jails use `storage.PData[player.index].manual_jail`, independently
of the vote tally in `banished`. Old saves migrate a 1000-point jail when there is
no active moderator vote explaining those points. `/unjail` clears the manual
jail and all votes against that player; `/overrule clear` explicitly clears all
banishments, including manual jails.

Weapon, ammo, and armor stashes store complete item stacks in their LuaInventories.
Older saves may also have `armor_equipment_data`; unstashing restores that data into
the stored armor before transferring it. Entries that cannot be restored remain
saved for another attempt.

Admin Island stores each visitor’s return surface index and position in
`storage.PData[player.index].admin_island_return`. It is cleared only after a
successful return teleport. The island itself is a persistent `admin-island` surface.

`storage.PData[player.index].essentials` holds the current join session's activity
wait, eight-second countdown, pending request ID, and ready flag. It is reset on
join and cleared on disconnect. `storage.SM_Store.tool_hints` is ChatWire's runtime
capability flag; `tool_hint_sequence` supplies persistent per-map request IDs.
The cross-map reminder timestamp lives in ChatWire's player database.

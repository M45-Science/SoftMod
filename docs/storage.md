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

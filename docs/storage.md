# Storage Table Overview

The mod uses a single global table named `storage` to keep persistent data for all systems. This is required because Factorio scenario scripts have limited options for storing global state.

`storage` has two main sections:

* `storage.SM_Store` – global mod settings and shared state.
* `storage.PData` – per-player data indexed by `player.index`.

Each system stores its values in these tables rather than creating additional globals. The structure is created during on_init by `STORAGE_CreateGlobal()` and `STORAGE_MakePlayerStorage()` in `storage.lua`.

When adding new fields, try to group them logically under these tables. For example, `storage.SM_Store.votes` holds active vote-banish information and `storage.PData[player.index].active` tracks whether a player was active this tick. Keeping related values together helps avoid conflicts and makes saved data easier to inspect.

## Module Storage Fields

### banish.lua
- `storage.SM_Store.votes` – list of active vote records `{voter, victim, reason, tick, withdrawn, overruled}`.
- `storage.SM_Store.sendToSurface` – queue for teleporting players after banish/unbanish.
- `storage.PData[index].banished` – non-zero when a player is jailed or banished.
- `storage.PData[index].reports` – count of `/report` uses by the player.

### quickbar.lua
- `storage.PData[index].qb_import_string` – quickbar configuration text awaiting import.

### stash.lua
- `storage.PData[index].gun_stash` – temporary inventory for guns.
- `storage.PData[index].ammo_stash` – temporary inventory for ammo.
- `storage.PData[index].armor_stash` – temporary inventory for armor.
- `storage.PData[index].armor_equipment_data` – saved equipment grid data when armor is stashed.

### online.lua
- `storage.SM_Store.pcount` and `storage.SM_Store.tcount` – online and total player counts.
- `storage.SM_Store.playerList` – cached table of player info for the online window.
- `storage.PData[index].onlineSub` – name of the player selected in the online submenu.
- `storage.PData[index].onlineBrief` – whether the brief view is enabled.
- `storage.PData[index].onlineShowOffline` – whether offline players are shown.

### onelife.lua
- `storage.SM_Store.oneLifeMode` – global flag enabling permadeath.
- `storage.PData[index].permDeath` – tracks confirm prompts before deleting a character.

# M45-SoftMod
[Command Overview](https://m45sci.xyz/help-factorio-staff.html)

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
### LUA scripts for M45's Factorio servers. ( softmod / scenario scripts )
Requires Factorio 2.0.27 or newer.
<br>
This mod keeps all persistent state in a global table named `storage`. See
[`docs/storage.md`](docs/storage.md) for an overview of its layout and
[`docs/in-place-upgrades.md`](docs/in-place-upgrades.md) for upgrade guardrails.
The system-only ChatWire interface is documented in
[`docs/chatwire-protocol.md`](docs/chatwire-protocol.md).
Admins can use `/admin-island` to visit a shared sunny island with sandy beaches,
stone paths, trees, and a fish pond. The 128 × 128 surface has an island roughly 74 tiles across and is created only on
the first visit.
Use the command again to return to your previous location (or the main spawn if
that surface was deleted). Enter on foot with a living character. Non-admins who
arrive through other teleport tools, or lose admin access while visiting, are
returned automatically. The island and any changes to it persist in the save.

The Help/Info button opens **M45 essentials**, a two-column grid with Membership,
Players, To-do, Toolbar Manager, Discord, and Patreon. Membership explains score,
levels, Banish, and Discord map voting. Details open on separate pages with Back
navigation; the main grid stays unchanged. The panel also appears eight seconds
after first activity, subject to ChatWire's shared daily/monthly cooldown.

## Development

A basic `luacheck` configuration is provided for optional linting:

```bash
luacheck *.lua
```

Regression tests use mocked Factorio APIs and run under Lua 5.2 from this directory:

```bash
lua5.2 tests/regressions.lua
```

If Lua 5.2 is unavailable locally:

```bash
docker run --rm -v "$PWD":/work:ro -w /work nickblah/lua:5.2-alpine lua tests/regressions.lua
```

These tests cover commands, inventory transfers, permissions, and save migrations;
they do not replace in-game testing.

`tests/admin-island/control.lua` is also a native Factorio test scenario. To run it,
copy that file and `admin_island.lua` into an isolated Factorio user-data directory
under `scenarios/admin-island/`, then run Factorio with that user-data configuration
and `--test-scenario admin-island --test-ticks 60`. It checks lazy creation, admin
access, terrain, return travel, persistent edits, and deleted return surfaces.

*banish.lua*<br>
Allows regulars to vote-ban players,<br>
<br>
*commands.lua*<br>
Server, moderator and player commands<br>
<br>
*control.lua*<br>
Main, loads modules<br>
<br>
*event.lua*<br>
Handles game events and ticks<br>
<br>
*storage.lua*<br>
Handles init of storage variables<br>
<br>
*info.lua*<br>
Help/Info toolbar entry and reset-clock controls
<br>
*essentials.lua*<br>
Essentials grid, feature explanations, links, and supporter credits<br>
<br>
*log.lua*<br>
Action logging<br>
<br>
*logo.lua*<br>
adds a custom logo to spawn<br>
<br>
*online.lua*<br>
menu that shows players online, with some actions:<br>
whisper, report and banish<br>
<br>
*perms.lua*<br>
passive anti-grief. new users permissions are limited,<br>
and players move up with activity<br>
<br>
*todo.lua*<br>
simple to-do list<br>
<br>
*utility.lua*<br>
commonly needed utility functions<br>
<br>
*onelife.lua*<br>
permadeath-onelife mode<br>
PlanetPicker note: SoftMod avoids teleporting players off the `empty_void` surface or forcing controller changes while PlanetPicker is using it for planet selection / limbo.<br>
<br>
*quickbar.lua*<br>
Save and restore quickbars through ChatWire. Exports use packed V3 (`Q3:`) or V2 when its compressed string is shorter. Imports accept V1, V2 and V3. V3 preserves modded item and quality names and up to 100 slot positions. [Quickbar Exchange specification](https://github.com/M45-Science/QuickbarExchange)

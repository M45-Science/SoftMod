# M45-SoftMod
[Command Overview](https://m45sci.xyz/help-factorio-staff.html)

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
### LUA scripts for M45's Factorio servers. ( softmod / scenario scripts )
<br>Currently approximately 3700 lines of lua.
<br>
This mod keeps all persistent state in a global table named `storage`. See
[`docs/storage.md`](docs/storage.md) for an overview of its layout and per-module fields.
When adding new storage keys, update that document and include a comment near the
code that creates or modifies the key. A basic
`luacheck` configuration is provided for optional linting:

```bash
luacheck *.lua
```

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
Welcome/info window<br>
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
<br>
*quickbar.lua*<br>
save/restore quickbar via chatwire<br>

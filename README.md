# M45-Factorio-Lua
LUA scripts for M45's factorio servers.

antigrief.lua
active system that prevents mining/rotating and fast-replace of entites new players do not own
and, blueprint throttling and limiting

banish.lua
allows regulars to vote-ban new/memeber level players,
and admin /damn

commands.lua
slash-commands (needs cleanup/splitting off)

control.lua
basically selects modules to load

event.lua
handles game events and ticks

globals.lua
handles init of global variables
(lots of code needs to be moved here)

info.lua
GUI welcome/info window

log.lua
action logging

logo.lua
adds a custom logo to spawn

online.lua
menu that shows players online, with some actions:
whisper, report and banish

perms.lua
passive anti-grief. new users permissions are limited,
and players move up with activity

todo.lua
simple todo list

util.lua
commonly needed utility functions
(could use cleanup, some code should be moved in/out)

img: all our custom images
preview.jpg, provides a logo image for save files

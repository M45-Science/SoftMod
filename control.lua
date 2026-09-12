-- Carl Frank Otto III
-- carlotto81@gmail.com
-- GitHub: https://github.com/M45-Science/SoftMod
-- License: MPL 2.0
local SM_VERSION = require("version")
require "banish"   -- Banish system
require "commands" -- Slash commands
require "event"    -- Event/tick handler
require "info"     -- Welcome/Info window
require "log"      -- Action logging
require "logo"     -- Spawn logo
require "onelife"  -- Hardcore / one life to live mode
require "online"   -- Players online window
require "perms"    -- Permissions system
require "storage"  -- Global variable init
require "todo"     -- To-Do-list
require "utility"  -- Widely used general utility
require "quickbar" -- Save or Restore Quickbar
require "stash" -- Save or Restore Weapon/Ammo/Armor
require "forcedel" -- Admin force-delete helper
require "chatwire" -- ChatWire machine protocol (load after command dependencies)

script.on_init(function()
    RunSetup()
    game.print("M45 Soft-Mod v" .. (storage.SM_Version or SM_VERSION or "?") .. " loaded.")
end)

script.on_configuration_changed(function()
    RunSetup()
end)

function RunSetup()
    storage.SM_Version = SM_VERSION
    storage.SM_OldVersion = storage.SM_OldVersion or "OldVersion"

    -- Ensure state exists even when versions match (hot reload / partial upgrades)
    STORAGE_CreateGlobal()
    TODO_Init()
    PERMS_EnsureGroups()
    PERMS_ApplyStaticPermissions()
    PERMS_SetPermissions()

    for _, player in pairs(game.players) do
        FORCEDEL_MakeButton(player)
    end

    -- Only rerun expensive setup on version change
    if storage.SM_OldVersion ~= SM_VERSION then
        storage.SM_OldVersion = SM_VERSION
        BANISH_MakeJail()
        UTIL_MapPin()

        game.forces["player"].friendly_fire = false -- disable friendly fire
        game.disable_replay()                       -- Smaller saves, prevent desync on script upgrade
        game.surfaces[1].show_clouds = false
    end

end

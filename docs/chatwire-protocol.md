# ChatWire protocol

SoftMod exposes one system-only command, `/chatwire`, and emits all custom
machine data with one `[CHATWIRE]` tag. The payload following either is JSON
encoded with Factorio's `helpers.encode_string`, which deflates and base64
encodes it.

The version 1 JSON envelope uses request IDs and distinguishes responses from
events. Supported requests are `hello`, `status`, `config`, `online`, `chat`,
`whisper`, `player-level`, `supporter`, `quickbar-result`, and `tool-hint-result`.

Player names in `whisper`, `player-level`, and `supporter` are matched
case-insensitively. Responses and events that include player names preserve
their in-game capitalization. These requests still require an online player.

Build 698 and newer emits `decon-depleted` and `undecon-depleted` activity
actions for mining drills with no resource entities anywhere in their mining
area. Cleanup remains auditable without per-entity deconstruction notices or
ChatWire suspicion/incident counts. A missing mining target alone is not enough:
unpowered or blocked drills with resources retain ordinary `decon`/`undecon`
actions. These actions use the existing version 1 activity envelope, and older
ChatWire builds already ignore them for scoring.

Real-engine validation lives in ChatWire's `support/native_factorio_test.go`.
See the sibling repository's `docs/native-factorio-tests.md` for the opt-in
command. It stages this source tree in temporary scenarios and covers engine
handshakes, quickbar storage/loading, previews, quit-save reloads and cleanup
moderation. The mock regression suite remains available with
`lua5.2 tests/regressions.lua` from this repository.

The existing player and moderator commands remain player-facing. In particular,
`/online` still opens or prints the in-game player list and retains its moderator
actions; only ChatWire's machine-side player-list transport uses `/chatwire`.

The first creation of a map's `storage.SM_Store` sets `storage.CW_MapPreviewPending`. This also handles newly generated saves into which ChatWire injects SoftMod after Factorio has already run `on_init`. The first `hello` emits a `map-preview` event with `data.exchange_string`, read from Factorio's `game.get_map_exchange_string()`. The pending flag is cleared after emission and persists with the save, so ordinary reloads and upgrades do not repost the link. If the export fails, the flag remains set for a later hello. ChatWire converts the exchange string into a FactMapGen URL and posts it in the server's chat channel.

`/map-preview` is also available on demand in Factorio and Discord. Factorio replies privately to the requesting player, or to RCON when called from the console. Discord invokes this fixed read-only command over RCON and returns an ephemeral link (or a text attachment for exceptionally long links). Register the new Discord slash command during the planned rollout; it requires the updated SoftMod to be loaded. Manual requests do not consume or repeat the automatic new-map announcement.

When ChatWire advertises `quickbar_presets` in `config`, SoftMod emits `quickbar-preset` events for `access`, `store`, `load`, or `rename`. ChatWire checks the player’s entitlement on each request and replies with `quickbar-result`, echoing the player name and request ID. Slot 1 is Default. A first-join access request can return that slot; later access requests return slot labels only. The labels array includes one entry per accessible slot, including empty slots. Members have two slots, Regulars have four, and Veterans have eight. In-game admins and linked Patreon or Supporter role holders have sixteen. Each limit includes Default, and the highest applicable limit wins. Default has a fixed name. Players may rename the other personal slots. A rename changes only its label. An empty label restores the built-in display name; omitting the label on store preserves the current name. SoftMod skips Store requests when the current toolbar matches the last successfully saved exchange for that slot, or an identical store is still pending. These session-only comparisons are cleared on access refresh and for a slot when it is loaded, so failed saves and refreshed external changes can be retried. Store and rename share a one-second per-player UI cooldown. ChatWire combines Store and Rename requests per player/slot and flushes each nonempty batch every five seconds. A `quickbar-result` with `pending=true` means queued, not saved; the matching final reply confirms persistence or reports a retryable error. The latest toolbar and label are merged independently. Each instance reads and merges under the shared file lock, and orderly shutdown flushes pending updates. Change detection remains in SoftMod. Loads and access checks remain unrestricted. Exchange strings use the existing M45 quickbar format.

Preset labels keep the existing 32-character limit. Rich-text tag syntax is rejected for Store/Rename in ChatWire and before submission in SoftMod. Ordinary bracketed names (such as `[Rail]`), Unicode and emoji remain supported; no additional player-name restrictions are applied. Legacy labels containing markup use the built-in slot name for display without rewriting the saved name or toolbar. Names continue to travel as encoded JSON data, never file paths or executable Lua.

When ChatWire enables `tool_hints` in config, SoftMod emits `tool-hint` with the
player `name` and numeric `id` after the eight-second first-activity delay. ChatWire
atomically claims the shared player-database cooldown and responds with
`tool-hint-result` (`name`, `id`, `allowed`). New/Member ranks wait 24 hours;
Regular/Veteran/admin ranks wait 30 days. There is no lifetime cap. The server's
wall clock controls this cooldown, so map time and switching maps do not reset it.
Responses only apply to the matching connected join session. Database failures
fail closed; old ChatWire builds do not enable automatic panels.

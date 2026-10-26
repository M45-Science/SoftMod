# ChatWire protocol

SoftMod exposes one system-only command, `/chatwire`, and emits all custom
machine data with one `[CHATWIRE]` tag. The payload following either is JSON
encoded with Factorio's `helpers.encode_string`, which deflates and base64
encodes it.

The version 1 JSON envelope uses request IDs and distinguishes responses from
events. Supported requests are `hello`, `status`, `config`, `online`, `chat`,
`whisper`, `player-level`, and `supporter`.

Player names in `whisper`, `player-level`, and `supporter` are matched
case-insensitively. Responses and events that include player names preserve
their in-game capitalization. These requests still require an online player.

The existing player and moderator commands remain player-facing. In particular,
`/online` still opens or prints the in-game player list and retains its moderator
actions; only ChatWire's machine-side player-list transport uses `/chatwire`.

The first creation of a map's `storage.SM_Store` sets `storage.CW_MapPreviewPending`. This also handles newly generated saves into which ChatWire injects SoftMod after Factorio has already run `on_init`. The first `hello` emits a `map-preview` event with `data.exchange_string`, read from Factorio's `game.get_map_exchange_string()`. The pending flag is cleared after emission and persists with the save, so ordinary reloads and upgrades do not repost the link. If the export fails, the flag remains set for a later hello. ChatWire converts the exchange string into a FactMapGen URL and posts it in the server's chat channel.

`/map-preview` is also available on demand in Factorio and Discord. Factorio replies privately to the requesting player, or to RCON when called from the console. Discord invokes this fixed read-only command over RCON and returns an ephemeral link (or a text attachment for exceptionally long links). Register the new Discord slash command during the planned rollout; it requires the updated SoftMod to be loaded. Manual requests do not consume or repeat the automatic new-map announcement.

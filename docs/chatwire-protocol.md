# ChatWire protocol

SoftMod exposes one system-only command, `/chatwire`, and emits all custom
machine data with one `[CHATWIRE]` tag. The payload following either is JSON
encoded with Factorio's `helpers.encode_string`, which deflates and base64
encodes it.

The version 1 JSON envelope uses request IDs and distinguishes responses from
events. Supported requests are `hello`, `status`, `config`, `online`, `chat`,
`whisper`, `player-level`, and `supporter`.

The existing player and moderator commands remain player-facing. In particular,
`/online` still opens or prints the in-game player list and retains its moderator
actions; only ChatWire's machine-side player-list transport uses `/chatwire`.

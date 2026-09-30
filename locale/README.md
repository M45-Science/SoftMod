# Localization Contributions

Translations for SoftMod live in this folder. If you spot problems or want to add a new language, please send us a pull request on GitHub.

1. Fork the project at <https://github.com/M45-Science/SoftMod>.
2. Create or edit `locale/<code>/locale.cfg`, where `<code>` is the Factorio language code. Use `locale/en/locale.cfg` as the reference for keys and meaning.
3. Commit your changes and open a pull request.

Even small fixes are welcome!

## Supported languages

| Code | Language |
| --- | --- |
| `en` | English |
| `de` | Deutsch |
| `es` | Español |
| `fr` | Français |
| `it` | Italiano |
| `pt` | Português (Brazilian wording) |
| `zh-CN` | 简体中文 (Simplified Chinese) |
| `zh-TW` | 繁體中文 (Traditional Chinese) |

The original Chinese translations were contributed by PHIDIAS.

## Translation guidance

- Keep the `[strings]` section and all keys from the English file. Translate the values after `=`, not the keys. Use UTF-8 and `;` for comments.
- Preserve Factorio placeholders such as `__1__`. These are substituted by Factorio; `%s` is not a localization placeholder. See the [LocalisedString documentation](https://lua-api.factorio.com/latest/concepts/LocalisedString.html).
- `todo_edit_warning` receives the names of players editing the item; `todo_id_error` receives the item ID. `info_score_l2_decon` and `info_score_l3_decon` receive Factorio's translated name for the deconstruction planner as `__1__`.
- Preserve rich-text tags such as `[color=orange]`, `[/color]`, and `[entity=behemoth-biter]`, as well as URLs, `/banish`, `!vote-map`, and `#moderation-help`.
- Keep brand names such as M45-Science, Discord, Patreon, and Steam recognizable. “Regulars” and “Veterans” are player ranks; “Vets” does not mean veterinarians.
- The activity score is not hours played. The membership level carries over between maps, but the score does not. A map rewind restores an earlier save; a map reset starts a new map.
- Use consistent terms for ranks and to-do items. Keep the form of address consistent within each language and button labels concise.
- Use Simplified Chinese and mainland wording for `zh-CN`, and Traditional Chinese and Taiwan wording for `zh-TW`.
- `info_relay_label` is retained for the currently disabled relay section.

After editing, check for missing or duplicate keys, matching placeholders and tags, and unchanged commands and links. Preview the affected windows in Factorio when possible.

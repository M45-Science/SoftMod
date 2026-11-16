# Toolbar icon sources

These editable 64 × 64 SVGs are the source artwork for the matching toolbar set.
The game loads the PNG exports in `../../img/buttons/`.

| Source | Runtime export |
| --- | --- |
| `help-info.svg` | `m45-64.png` |
| `players.svg` | `online-64.png` |
| `to-do.svg` | `todo2-64.png` |
| `toolbar-manager.svg` | `exchange-64.png` |
| `admin-delete.svg` | `force-delete-64.png` |
| `admin-delete-armed.svg` | `force-delete-armed-64.png` |

Labels use DejaVu Sans Bold. Render at the SVG's native 64 × 64 size with a
transparent background. For example, from this directory:

```bash
convert -background none help-info.svg ../../img/buttons/m45-64.png
```

Button actions, permissions, unread badges, and the admin delete tool's armed artwork and native
toggled-state highlight remain controlled by the existing Lua code.

Toolbar buttons use a 72 × 72 widget with zero style padding. Factorio reserves
a four-pixel inset on each side of a sprite button, leaving a native 64 × 64
image area at 100% UI scale. Preview screenshots should use
`ui-scale-mode=manual-pixels` and `custom-ui-scale=1` and must not resize crops.

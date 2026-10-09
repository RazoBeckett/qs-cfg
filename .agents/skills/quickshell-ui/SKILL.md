---
name: quickshell-ui
description: Visual consistency for any Quickshell shell. Theme tokens, corner scale, typography, icons, clipping, shared components, empty states, and motion styling. Use when adding or changing any visible surface.
---

# Quickshell UI

Generic visual rules for any Quickshell project. No project specific settings, paths, or font picks live here. Match the host theme instead of reusing example values.

Use `quickshell` skill for surfaces, services, multimonitor scope, and run loop. Use this skill for what the eye sees.

## Steps

Do these in order. Each step states how you know it is done.

1. **Read the host theme first.** Find where colors, type, spacing, and radii live, usually `theme/` singletons. Note the label font, mono font, and icon font actually installed.
   Done when you can name the token files and the three font families without guessing.

2. **Use one corner scale.** Pick four levels for outer shells, nested cards, small controls, and hairlines. Derive them from one base value so a restyle edits one place. Never write a literal radius at a call site.
   Done when every `radius:` in touched files names the scale and zero stays zero at every level.

3. **Clip what bleeds.** A container whose children reach its edges such as images, sidebar fills, or preview art becomes a clipping container that keeps rounded corners intact. Simple cards stay a plain shape with `clip: true`.
   Done when rounded containers show no square corner poke at any scale value including 0.

4. **Set type by role.** Body and headings take the sans family. Clocks, percentages, and numeric columns take mono so characters align. Glyphs take the icon font only. Set family and pixel size from the theme and weight on the item. Never pair a grouped `font:` binding with a `font.*` override on the same item, since evaluation order clobbers it.
   Done when every touched text follows the rule and weight matches place in hierarchy.

5. **Reuse shared components.** Buttons, sliders, toggles, labels, cards, and popups take scale defaults once. Delete per call radius overrides except named compact variants so a theme change propagates with no per call edits.
   Done when a rounding or font change restyles every touched surface with no extra edits.

6. **Bound text you do not control.** Size pills and cards from content with `implicitWidth` and `implicitHeight`. Cap system or media text with `Layout.maximumWidth` plus `Text.ElideRight` so a long title never pushes other controls off screen. Give media, network, and hardware an explicit empty state. A blank element reads as broken.
   Done when a 200 character label stays bounded and disconnected or missing hardware still renders clean.

7. **Verify looks and motion.** Check contrast on small text, icon glyphs against the installed font release, entrance and exit motion, and all connected monitors.
   Done when small text stays readable, glyphs match the font in use, transitions run smooth twice in a row, and per monitor windows hold.

## Reference

### Theme tokens

One way flow. Config feeds theme, theme feeds interface. A component reads a token and never writes one, so a full restyle happens from one place.

- Colors for every background, foreground, border, and accent.
- Type for sans, mono, and icon families plus the size ramp.
- Spacing for bar height, outer margins, module gaps, and control padding.
- Radii for the four corner levels.

Hard coded colors, font names, pixel sizes, or radii at call sites are defects. Move them into tokens.

### Type

Three families, ever. Sans for nearly everything. Mono where characters must align. Icons for glyphs only.

```qml
Text {
  font.family: Theme.sans.family
  font.pixelSize: Theme.sans.pixelSize
  font.weight: Font.DemiBold
}
```

Headings and buttons take `Font.DemiBold` to `Font.Bold`. Body stays `Font.Normal`. Captions take `Font.Normal` or `Font.Medium`.

### Icons

Two strategies, both valid. Ligatures use readable names such as `wifi` when the icon font supports them. Codepoints use `String.fromCodePoint(...)` so source never holds private use characters directly. Never paste raw glyphs into source.

Verify codepoints against the installed font release. Battery and wifi tiers often sit at consecutive codepoints with gaps and one off states apart, so sequential math plus direct addresses for outliers is the normal shape.

### Shared component shape

Inputs first, drawing second. Name the properties a caller controls such as `icon`, `label`, `iconColor`, `maxLabelWidth`, and `active` before drawing anything. Keep `Process`, `Timer`, and service objects out of the visual file. Every value shown comes from a declared property.

### Motion styling

Animate one number from 0 to 1 and derive position, radius, and opacity from it with arithmetic. Attach one `Behavior` with a `NumberAnimation` to that driver. Multiple behaviors on dependent properties chase each other and freeze then lurch.

Keep idle hidden items a hair above zero opacity so the renderer stays warm. Fully transparent items build their first frame during the fade, so entrances stutter while exits look fine.

### Reference links

- [Quickshell introduction](https://quickshell.org/docs/v0.3.1/guide/introduction/)
- [Type reference](https://quickshell.org/docs/v0.3.1/types/)
- [Qt QML documents](https://doc.qt.io/qt-6/qtqml-documents-topic.html)
- [Qt item size and positioning](https://doc.qt.io/qt-6/qtquick-positioning.html)

# QML essentials for Quickshell

Covers the Qt 6 QML subset a shell author uses daily. Full reference starts at `https://doc.qt.io/qt-6/qtqml-documents-topic.html`.

## Documents and types

A QML file is imports plus one root object.

```qml
import QtQuick
import QtQuick.Layouts

Item {
  property string label: "hi"
  Text { text: label }
}
```

Capitalized names are types. Lowercase names are properties. A file named `MyButton.qml` with a matching root type becomes `MyButton {}` for files beside it. An inline `component MyComp: Item {}` stays scoped to its file and can see that file's ids. `id` values are file scoped, lowercase by convention, and are not real properties, so never reach across a `Component` boundary with an `id`. Expose a root property and bind to it instead.

## Properties

Declare with this shape:

```qml
[required] [readonly] [default] property <type> <name>[: binding]
```

Use `var` only when no concrete type fits. Mark computed state `readonly` so readers know not to assign it. Name derived state so call sites read plainly, for example `muted` instead of `sync.audio.muted`. Keep `parent` out of logic where an `id` works, since `parent` shifts as the tree changes.

## Bindings beat assignments

`text: Qt.formatDateTime(clock.date, "HH:mm")` declares a relationship. The engine keeps it current. There is no refresh call to write.

A binding breaks the moment plain JS assigns the same property, including inside `Component.onCompleted`. That assignment runs once. To restore a live relationship from JS, assign `Qt.binding` with a function.

```qml
Component.onCompleted: label = Qt.binding(() => source.text)
```

Keep binding expressions short. Move branching into a function the binding calls. Never depend on evaluation order between bindings.

## Signals

Declare with `signal`, emit by calling it, handle with `on` plus a capital first letter.

```qml
signal pressed(index: int)
onPressed: (index) => root.select(index)
```

Every property has an implicit `on<Name>Changed` handler. For targets outside the file, such as singletons, use `Connections` with a `target`. Use `Component.onCompleted` for init work only.

## Anchors

Anchors place one item against its parent or a sibling. The seven lines are left, horizontal center, right, top, vertical center, baseline, and bottom. Helpers are `anchors.fill`, `anchors.centerIn`, `anchors.margins`, per edge margins, and offsets.

Rules that prevent the common bugs:

- Do not mix anchors with `x`, `y`, `width`, or `height` on the same axis. The result is undefined.
- Anchor only to the direct parent or a sibling.
- Do not flip an anchored edge with a conditional binding. Unset first in JS or use `AnchorChanges` with states, or the layout stretches during the switch.
- Read the Qt page on item size and positioning before building a bar. Anchors are not flexbox and there is no CSS box model.

## Layouts

Layouts place groups. `RowLayout`, `ColumnLayout`, and `GridLayout` come from `QtQuick.Layouts`. Children take `Layout.fillWidth`, `Layout.fillHeight`, preferred and minimum sizes, alignment, row and span. The default spacing is 5.

Rules:

- Put geometry on the layout container, not on children inside it. Only the root layout gets `anchors.fill: parent`.
- A middle `Item { Layout.fillWidth: true }` acts as a spring and pushes left and right groups apart.
- Use separate spacing values for structure versus control groups. An outer bar gap of 6 to 8 differs from an inner status group gap near 25.
- Prefer layouts over legacy `Row` and `Column`, which lack attached `Layout` props and break pixel alignment.
- Never bind `Layout.preferredWidth` back to the size the layout computes. That loop stalls the view.

Single child placement uses anchors. A row of children uses a layout, then anchor that layout. Example:

```qml
RowLayout {
  anchors.centerIn: parent
  spacing: 10
  Text { text: "a" }
  Text { text: "b" }
}
```

## Size flow

Actual size flows down. Desired size flows up. `width` and `height` are what the parent gave. `implicitWidth` and `implicitHeight` are what the child wants. Containers size from child implicit size. Children size from parent actual size. A zero size default is the usual blank screen bug.

Never compute implicit size from `childrenRect`, which tracks actual geometry and loops. Sum child implicit sizes by hand or wrap the child in `WrapperItem` or `MarginWrapperManager` from `Quickshell.Widgets` and let it forward the size plus margin.

## Lists and deferred work

- `Repeater { model: 9 }` stamps N copies now. Each delegate sees `index`, `modelData`, and model roles. Good for fixed sets such as nine workspaces.
- `ListView` virtualizes long or scrolling lists. Use it when `Repeater` would build hundreds of items.
- `Loader` with `active` and `asynchronous` defers one branch. Quickshell adds `LazyLoader` for panels that should cost nothing until first open, such as launchers and calendars.
- `Variants` is the non item repeater. It stamps windows and other non visual objects, which is why screens use it. See `surfaces.md`.
- For imperative creation, keep a `Component` and call `createObject`.

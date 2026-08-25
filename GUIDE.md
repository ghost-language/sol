# Getting started in Sol

This is the deeper tour README.md points to: how the pieces fit together,
what a click actually does on its way to an app, and what to copy when you
add your own. Read `README.md` first for the one-paragraph version and the
two scoping gotchas - this assumes both.

## Run it, then read it

```bash
lumen .
```

Everything Sol draws lives in a fixed 480x270 space, scaled up pixel-perfect
to whatever window it's given (`main.ghost` picks the starting scale; nothing
past that point ever measures itself against the real window). Open a
terminal alongside the window - Ghost failures land on screen *and* on
stderr, so `lumen . 2>&1 | less` catches anything that scrolls past.

There's no build step. Every `.ghost` file is read fresh each run, and a
bare (no-scheme) import like `import App from 'apps/app'` resolves to a
sibling `.ghost` file by path, the same way `lumen:canvas` resolves to a
module Lumen registers and `ghost:math` to one Ghost's standard library
does.

## The frame, end to end

`main.ghost` is the only file Lumen calls directly - `load()` once, then
`update(dt)` and `draw()` every frame, `keypressed`/`textinput`/`wheelmoved`
on input. It builds one `context` object - `{ wm, vfs, settings,
previewScreensaver }` - once, and every app and desktop piece is handed the
same reference. There's no global lookup for "the window manager" or "the
disk"; whatever needs one gets it threaded through its constructor.

A click's path through that context, roughly:

1. `main.update(dt)` asks the taskbar first (`taskbar.update(dt)` - the start
   menu floats above everything else, so it has to see the click before
   anything under it does), then the window manager
   (`wm.update(dt, taskbarConsumed)`), then the desktop, each told whether an
   earlier stage already claimed the click so a click-through doesn't also
   land on whatever was underneath.
2. `WindowManager.update()` figures out which window (if any) the click hit,
   focuses it (`bringToFront`), and handles chrome - the close button, the
   resize grip, dragging the titlebar - itself. Anything not chrome gets
   passed down to the focused app as `pointer`.
3. Every window's app gets an `update(dt, pointer)` call each frame, but only
   the focused *and* hovered one gets a live `pointer` - `{x, y, down,
   pressed, released, wheel, hover}`, already translated into the app's own
   0,0 content space. Every other open window gets a dead one
   (`hover: false`, nothing down), so a background window's buttons never
   fire just because the mouse happens to be over them.
4. `draw()` mirrors this: desktop wallpaper and icons, then every window
   (oldest to newest, so focus order is stacking order), then the taskbar
   and start menu on top of all of it.

Screensaver and idle timeout are handled entirely in `main.ghost`, ahead of
this whole chain - `update()` returns early into `updateScreensaver`/
`updateIdle` instead of touching the desktop at all while one is active.

## What a window expects from an app

`window.ghost`'s comment is the actual contract; this is the same thing with
the reasoning attached. An app is a plain object (or a class instance - Sol
uses classes throughout, but nothing requires it) with:

- `title`, `width`, `height` - read once, at `wm.open(app)` time, to build
  the `Window` wrapper.
- `draw(w, h, pointer)` - required. `w`/`h` are the window's *current*
  content size (it may have been resized since `open()`), not the app's
  original `width`/`height` - see File Manager's `draw()` resizing its list
  and text field to match every frame.
- `update(dt, pointer)`, `keypressed(key)`, `textinput(text)`, `onClose()` -
  all optional, called if present and skipped if not, the same way Lumen
  treats a game's own callbacks.
- `minWidth`, `minHeight`, `resizable` - optional; `Window`'s constructor
  falls back to `90`/`54`/`true` when an app doesn't set them.

Nothing here requires extending anything. `apps/app.ghost`'s `App` exists
because four apps kept re-declaring the same handful of fields and a
near-identical timed status message (Text Edit's old
`status`/`statusTimer`, File Manager's `message`/`messageTimer`) - it isn't
load-bearing the way the contract above is.

### `App`, and what it buys you

```ghost
class MyApp extends App {
  constructor(context) {
    super.constructor(context, 'My App', 200, 140)

    // this.context, this.title, this.width, this.height are set.
    // this.minWidth = 90, this.minHeight = 54, this.resizable = true,
    // this.dirty = false - override any of these afterward if you need to.
  }

  update(dt, pointer) {
    super.update(dt, pointer)   // ticks the message timer down

    // ...your own per-frame work
  }

  draw(w, h, pointer) {
    // ...your own drawing

    this.drawMessageBar(w, h)   // draws this.message if showMessage() is live
  }
}
```

`showMessage(text, duration = 2)` sets a status line; `drawMessageBar(w, h)`
draws it as a translucent strip along the bottom of the window, the same
place and style in every app that uses it (Text Edit's "Saved", File
Manager's "Already exists", Pixel Art's "Nothing to save this as yet"). Call
`super.update(dt, pointer)` from your own `update` to keep the timer
counting down - it's the one piece of `App` that has to be reached by hand
rather than inherited for free, the same way `ToggleButton.draw()` calls
`super.draw(pointer)` in `widgets.ghost` before adding its own highlight.

Skip extending `App` for something that genuinely has no state and no
message to show - `About` extends it today mostly to prove the base doesn't
get in the way even there, not because it needs to.

## Adding an app

Follow an existing one - `apps/textedit.ghost` for something that reads and
writes a file, `apps/pixelart.ghost` for something with its own drawn
canvas and a small palette of tool buttons. In order:

1. New file in `apps/`, a class extending `App`, `super.constructor(context,
   title, width, height)` first thing in the constructor.
2. Wire it into both launch points - `desktop.ghost`'s `Desktop.buildIcons()`
   (needs a glyph function; copy the shape of `drawDocumentGlyph` or
   `drawPixelArtGlyph`, drawn with `canvas` primitives, never an image) and
   `taskbar.ghost`'s `StartMenu`'s `this.items` list. Both just call
   `context.wm.open(new YourApp(context))`.
3. If it opens files from File Manager, extend `FileManager.activate()`'s
   `if (entry.kind == 'folder') ... else if (...) ... else` chain rather
   than replacing it - see how Pixel Art's `.pixel` branch sits ahead of the
   `TextEdit` fallback.
4. Persist through `context.vfs`, never `lumen:filesystem` directly - it
   sandboxes to Lumen's save directory and keeps the manifest File Manager
   lists from drifting. `vfs.readFile`/`writeFile` for plain text;
   `ghost:json`'s `json.encode`/`decode` around a plain map or list for
   anything structured (see `PixelArt.save()`/`load()`).

## Where things live, and why

- **`theme.ghost`** - every color, font, and metric, plus a few shared draw
  helpers (`drawPanel`, `drawInset`, `hitTest`). Nothing picks its own
  color; if a new one is needed, it goes in `theme` first.
- **`widgets.ghost`** - `Button`, `ToggleButton`, `ScrollList`, `TextField`.
  All four are driven the same way: `update(pointer, dt)` then
  `draw(pointer)`, `pointer` being the same window-local, hit-tested mouse
  state apps get. Reach for one of these before hand-rolling a clickable
  rectangle - Pixel Art's palette swatches are the one place that *didn't*
  fit the mold (no label, selection ring instead of a fill change) and got
  custom hit-testing instead, the same way desktop icons do.
- **`window.ghost`** - `Window` (chrome around one app) and `WindowManager`
  (the list of them, focus, drag, resize). This is the one place that reads
  an app's `title`/`width`/`height`/`resizable`/`minWidth`/`minHeight`.
- **`vfs.ghost`** - Sol's sandboxed disk. Every directory keeps a
  `.sol-index.json` manifest recording folder-vs-file, because
  `lumen:filesystem` can list names but not tell the two apart.
- **`apps/`** - one file per app, plus `apps/app.ghost`'s shared base.

## Two more things that will bite

Beyond the two in `README.md` (closures in a `for` loop, and
`this.action(...)` on a dynamically-set field):

- **A window's `draw(w, h, pointer)` gets the *current* size, not the size
  you opened it at.** An app with any fixed-position layout (a save button
  pinned to the top-right, say) has to re-derive that position from `w`/`h`
  every frame, as Text Edit's `draw()` does with
  `this.saveButton.x = w - 38`. `PixelArt` sidesteps this by setting
  `resizable = false` - reach for that instead of fighting layout math when
  an app's content genuinely doesn't benefit from more room.
- **Only the focused, hovered window gets a live pointer.** If an app seems
  to stop responding to clicks, check whether something above it (a modal
  state, a dialog) needs to be closed first, or whether the window lost
  focus - `pointer.hover` is `false` and every other pointer field is inert
  whenever that's true.

## Smoke-testing a change without clicking through the UI

Lumen runs headless through SDL's dummy driver, which is how `make examples`
checks every example in the Lumen repo without a display. The same trick
works here: temporarily construct an app and call its `draw()`/`update()`
directly from `main.ghost`'s `load()` with a fake pointer -

```ghost
function deadPointer() {
  return { x: -1, y: -1, down: false, pressed: false, released: false, wheel: 0, hover: false }
}
```

- and run:

```bash
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 5 lumen . 2>&1
```

A syntax or runtime error prints (and the process exits non-zero) instead of
opening a window and waiting for a screenshot. `console.log(...)` reaches
the same stderr/stdout, which is enough to check things like a save/load
round trip without a mouse. Pull the scaffolding back out of `main.ghost`
before committing - it's a debugging aid, not part of the app.

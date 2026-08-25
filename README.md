# Sol

A fantasy workstation for [Ghost](https://github.com/ghost-language/ghost) and
[Lumen](https://github.com/ghost-language/lumen), in the spirit of
[Picotron](https://www.lexaloffle.com/picotron.php): a small windowed desktop
with its own disk, drawn at a fixed 480x270 (16:9) and scaled up pixel-perfect
to whatever window it's given.

Sol is Ghost source and nothing else - no images, no external assets. Every
wallpaper, icon, and screensaver is drawn with Lumen's `canvas` module.

## Running it

Sol needs [Lumen](https://github.com/ghost-language/lumen) (which needs
[Ghost](https://github.com/ghost-language/ghost) as a sibling checkout - see
its own README) and the SDL2 development libraries Lumen links against. If
you're working in this repo through Claude Code on the web, `.claude/hooks/session-start.sh`
sets all of that up automatically.

```bash
lumen .
```

## What's here

- **Desktop** - a wallpaper, a column of icons, and a start menu / taskbar.
  Double-click an icon or a start menu entry to open an app.
- **Window manager** - draggable titlebars, a resize grip, click-to-focus,
  and a close button. Every app is chrome wrapped around a plain object with
  a `draw(w, h, pointer)`; see `window.ghost`'s comment for the rest of the
  contract. `apps/app.ghost`'s `App` is an optional base class every
  built-in app extends, for the fields a window expects and a shared timed
  status message.
- **File Manager** - browses Sol's own disk (`vfs.ghost`), sandboxed to
  Lumen's save directory rather than the real filesystem. Create, rename, and
  delete folders and files.
- **Text Edit** - opens a file from File Manager, or starts blank; edits and
  saves back to the same disk.
- **Pixel Art** - a small sprite editor against a fixed ten-color palette,
  laid out like Picotron's own Image Editor: an icon toolbar down the left
  edge (pencil, fill, eyedropper, eraser) beside the canvas, palette as a
  grid below it. Opens blank from the desktop or start menu; File Manager
  opens any file ending in `.pixel` here instead of in Text Edit.
- **Settings** - pick a wallpaper or a screensaver, and how long the machine
  sits idle before the screensaver takes over.
- **About Sol** - the smallest possible app, mostly there to prove one only
  needs a title, a size, and a `draw()`.

See `GUIDE.md` for a fuller tour of the codebase - the frame loop, the app
contract, the two Ghost scoping gotchas below in more depth, and how to add
a new app.

## Layout

```
main.ghost           entry point: window setup, the frame loop, idle/screensaver
theme.ghost           shared colors, metrics, fonts
widgets.ghost         Button, ToggleButton, ScrollList, TextField
window.ghost           Window chrome + WindowManager
desktop.ghost           wallpaper + desktop icons
taskbar.ghost            start menu + open-window strip + clock
wallpapers.ghost         procedurally drawn wallpapers
screensavers.ghost        procedurally animated screensavers
vfs.ghost                Sol's own sandboxed disk
settings.ghost            saved preferences (wallpaper, screensaver, idle time)
apps/                    the built-in apps
```

## A note on Ghost's scoping

Two things about Ghost bite here more than they do in a typical script, and
are worth knowing before adding a third:

- **Assignment is scoped to the enclosing function, not the block.** A closure
  built inside a `for` loop closes over the loop's own variable, not a fresh
  copy of it - see `settingsapp.ghost`'s `wallpaperToggle`/`screensaverToggle`
  and `taskbar.ghost`'s `launcher` for the fix (give the closure its own
  function call to be built inside).
- **A class instance's dot-call syntax only resolves methods declared on the
  class.** A field set dynamically in a constructor (`this.action = fn`) is
  readable as a property but cannot be *called* as `instance.action(...)` -
  read it into a local first (`action = this.action; action()`). The same
  goes for `this` inside a closure: a function literal gets its own `this`
  when called, not whatever `this` was where it was written, so a closure
  that needs the enclosing instance captures it explicitly (`self = this`,
  then `self.whatever` inside the closure).

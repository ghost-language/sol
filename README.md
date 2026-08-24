# Sol

A fantasy workstation for [Ghost](https://github.com/ghost-language/ghost) and
[Lumen](https://github.com/ghost-language/lumen), in the spirit of
[Picotron](https://www.lexaloffle.com/picotron.php): a small windowed desktop
with its own disk, drawn at a fixed 480x270 (16:9) and scaled up pixel-perfect
to whatever window it's given.

It looks like a clear night in a city: near-black glass, cool grey chrome, and
one violet accent. Nothing on screen is antialiased or half a pixel wide - even
the text is drawn as rectangles rather than as font textures, so every letter
lands on whole pixels however far up the desktop is scaled.

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

- **Desktop** - a wallpaper, a column of icons, and a menu bar across the top
  holding the system menu, a tab per open window, and the clock. Double-click an
  icon, or pick an entry from the system menu, to open an app.
- **Window manager** - draggable titlebars, a resize grip, click-to-focus,
  and a close button. Every app is chrome wrapped around a plain object with
  a `draw(w, h, pointer)`; see `window.ghost`'s comment for the rest of the
  contract.
- **File Manager** - browses Sol's own disk (`vfs.ghost`), sandboxed to
  Lumen's save directory rather than the real filesystem. Create, rename, and
  delete folders and files.
- **Text Edit** - opens a file from File Manager, or starts blank; edits and
  saves back to the same disk.
- **Settings** - pick a wallpaper or a screensaver, and how long the machine
  sits idle before the screensaver takes over.
- **About Sol** - the smallest possible app, mostly there to prove one only
  needs a title, a size, and a `draw()`.

## Making it yours

Three things are PNGs rather than code, and Sol reads yours in preference to the
ones it ships with. They live on Sol's own disk - the sandboxed save folder,
which File Manager is browsing when it says "Disk":

| Drop a PNG at        | To replace                                  |
| -------------------- | ------------------------------------------- |
| `cursor.png`         | the pointer                                 |
| `icons/files.png`    | a desktop icon - also `textedit`, `settings`, `about` |
| `wallpapers/*.png`   | nothing; each one becomes a new choice in Settings |

Icons are 20x20 and the pointer is drawn from its top-left corner, both at one
image pixel per desktop pixel. A wallpaper is centred at whole-number scale
rather than stretched to fit, so a 240x135 PNG doubles cleanly to fill the
screen and a 1920x1080 one is shown at its middle. Anything missing falls back
to what Sol draws itself, so a half-filled `icons` folder is fine.

## Layout

```
main.ghost           entry point: window setup, the frame loop, idle/screensaver
pixelfont.ghost       the bitmap font, drawn as rectangles
theme.ghost           shared colors, metrics, fonts
assets.ghost          PNG loading, from Sol's disk or its own assets folder
widgets.ghost         Button, ToggleButton, ScrollList, TextField
window.ghost           Window chrome + WindowManager
desktop.ghost           wallpaper + desktop icons
menubar.ghost            system menu + open-window tabs + clock
wallpapers.ghost         flat colors, simple patterns, and PNG wallpapers
screensavers.ghost        procedurally animated screensavers
vfs.ghost                Sol's own sandboxed disk
settings.ghost            saved preferences (wallpaper, screensaver, idle time)
assets/                  the PNGs Sol ships with
apps/                    the built-in apps
```

## Why the text is drawn as rectangles

Sol draws in a 480x270 space and scales it up in whole steps, which is fine for
everything that is geometry and fatal for anything that is a texture. A TrueType
glyph is a texture: rasterised once at six pixels tall, then blown up three or
four times on its way to the screen. The antialiasing that makes it readable at
its own size is what turns it to grey mush at three times that.

`pixelfont.ghost` sidesteps it. Glyphs are authored as rows of `.` and `#`, six
rows of cap band plus a seventh for descenders, and compiled once at startup
into horizontal runs - so drawing a character is a handful of `filledRectangle`
calls. Rectangles are scaled before they are rasterised, so the letters land on
whole pixels at every multiple, exactly like the window chrome around them.

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

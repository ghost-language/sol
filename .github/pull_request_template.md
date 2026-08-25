## Overview

<!--
What does this PR do, and why? A sentence or two of context, then whatever
detail a reviewer needs to judge it.

When the change affects behavior a person clicking through Sol would
notice, show it - a short Ghost snippet and what it produces, before and
after, says more than a paragraph of description. When the change is
internal (window management, vfs, tooling), a short before/after snippet
or a pasted terminal/error output works the same way.

A bug fix, shown rather than described:

    // before: a folder's manifest entry never removed on delete, so File
    // Manager kept listing it after vfs.remove() returned true
    // after:  remove() only reports success once the manifest is written

A new app method other apps can now rely on:

    context.vfs.exists(path, name)   // true
-->

## Changes

<!--
Follow https://keepachangelog.com/ - delete any heading below with nothing
under it, so the rendered PR only shows the categories that apply.
-->

### Added
-

### Changed
-

### Deprecated
-

### Removed
-

### Fixed
-

### Security
-

## Screenshots

<!--
For anything that changes what Sol draws or how it looks running - a new
app, a layout change, a new wallpaper or screensaver, a widget tweak -
include a before/after screenshot or GIF. `canvas.screenshot()` from
inside a running app, or a host screenshot of `lumen .`, are the easiest
ways to get one. Delete this section for a change with no visual effect.
-->

## Related issues

<!-- e.g. Closes #123, Relates to #45 -->

## Additional context

<!--
Anything else a reviewer should know: design tradeoffs considered, terminal
output worth pasting for a diagnostics change, follow-up work intentionally
left out, and so on.
-->

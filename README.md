<!-- markdownlint-disable MD033 MD060 -->
# ResPlayer

<div align="center">
  <img src="logo.png" alt="ResPlayer logo" width="200">
</div>

[![Build](https://github.com/biyuehu/resplayer/actions/workflows/build.yml/badge.svg)](https://github.com/biyuehu/resplayer/actions/workflows/build.yml) [![License: GPL-3.0-only](https://img.shields.io/badge/License-GPL--3.0--only-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) ![ReScript](https://img.shields.io/badge/ReScript-white?logo=rescript)

A minimal, declarative music player written in [ReScript](https://rescript-lang.org/) — with lyrics scrolling, playlist support, playback-error recovery, light/dark theming, and a small imperative API (play, pause, next, prev, show, hide, destroy, ...). Inspired by [APlayer](https://github.com/DIYgod/APlayer)'s configuration style, but rebuilt from scratch as a small, dependency-light state machine plus an HSX-rendered view layer.

Originally a migration of an old vanilla-JS player, ResPlayer keeps the same declarative "just pass a config object" feel while being fully typed and usable from both ReScript and plain JS/TS projects.

## Features

- Declarative configuration, similar to APlayer (`container`, `audio`, `color`, `theme`, `fixed`, `autoplay`, `order`, ...)
- Play / pause / toggle / prev / next / seek, with a click-to-seek progress bar
- Three playback modes: list loop, single-track loop, and shuffle
- LRC-style lyric parsing with live scrolling, and immediate re-sync on seek
- Automatic skip-to-next on playback error, with a safety stop if every track in the playlist fails
- Optional `fixed` mode to dock the player at the bottom of the page
- Light / dark / auto (follows `prefers-color-scheme`) theming, plus a one-line accent color override
- An imperative instance API for programmatic control: `play`, `pause`, `toggle`, `next`, `prev`, `seek`, `setVolume`, `toggleList`, `togglePlayMode`, `setColor`, `setTheme`, `show`, `hide`, `isHidden`, `destroy`
- Usable from ReScript directly, or from plain JavaScript/TypeScript via generated TypeScript types (powered by [genType](https://rescript-lang.org/docs/gentype/latest/introduction))

## Installation

```bash
npm install
npm run res:build
```

This compiles the `.res` sources in `src/` into ES modules (`*.res.mjs`) alongside generated TypeScript type definitions (`*.gen.tsx`), using [ReScript](https://rescript-lang.org/)'s built-in genType support.

For local development with Vite (auto-recompiles ReScript on save):

```bash
npm run dev
```

## Usage

### From plain JavaScript / TypeScript

```js
import {
  makePlayer,
  playInstance,
  pauseInstance,
  toggleInstance,
  nextTrack,
  prevTrack,
  setInstanceTheme,
  hideInstance,
  showInstance,
  destroyInstance,
} from "resplayer/src/RPlayer.res.mjs";
import "resplayer/src/RPlayer.css";

const instance = makePlayer({
  container: document.getElementById("aplayer-global"),
  fixed: true,
  autoplay: true,
  order: "random", // "list" | "loop" | "random"
  color: "#3498db", // any CSS color, overrides the accent/primary color
  theme: "auto", // "light" | "dark" | "auto"
  audio: [
    {
      name: "Wake (Live)",
      artist: "Hillsong Young & Free",
      url: "https://example.com/song.mp3",
      cover: "https://example.com/cover.jpg",
      lrc: "[00:14.57]At break of day\n[00:16.58]in hope we rise\n...",
    },
    // ...more tracks
  ],
  titleChange: true,
  showList: false,
  debug: false,
});

// Imperative control, e.g. wiring up your own UI:
playInstance(instance);
pauseInstance(instance);
toggleInstance(instance);
nextTrack(instance);
prevTrack(instance);
setInstanceTheme(instance, "dark");
hideInstance(instance);
showInstance(instance);

// Clean up when you're done with it:
destroyInstance(instance);
```

Thanks to genType, TypeScript projects get full type checking and autocomplete on the config object and instance methods out of the box.

### From ReScript

```res
let instance = RPlayer.make({
  container,
  fixed: Some(true),
  autoplay: Some(true),
  order: Some(Random),
  color: Some("#3498db"),
  theme: Some(AutoTheme),
  audio: [
    {name: "Wake (Live)", artist: "Hillsong Young & Free", url: "...", cover: Some("..."), lrc: Some("...")},
  ],
  titleChange: Some(true),
  showList: Some(false),
  debug: Some(false),
})

RPlayer.play(instance)
RPlayer.next(instance)
RPlayer.setTheme(instance, Dark)
RPlayer.hide(instance)
RPlayer.destroy(instance)
```

## Configuration reference

| Field         | Type                              | Default   | Description                                              |
|---------------|------------------------------------|-----------|------------------------------------------------------------|
| `container`   | `HTMLElement`                      | required  | Element the player mounts into                             |
| `audio`       | `Array<{name, artist, url, cover?, lrc?}>` | required  | Playlist                                                    |
| `fixed`       | `boolean`                          | `false`   | Dock the player to the bottom of the viewport               |
| `autoplay`    | `boolean`                          | `false`   | Start playing the first track on mount (desktop only)       |
| `order`       | `"list" \| "loop" \| "random"`     | `"list"`  | Initial playback mode                                       |
| `color`       | `string` (any CSS color)           | —         | Overrides the player's primary/accent colors                |
| `theme`       | `"light" \| "dark" \| "auto"`      | —         | Color scheme; `"auto"` follows `prefers-color-scheme`       |
| `titleChange` | `boolean`                          | `true`    | Reflect the currently playing track in `document.title`     |
| `showList`    | `boolean`                          | `false`   | Expand the playlist panel on mount                          |
| `debug`       | `boolean`                          | `false`   | Reserved for future debug logging                           |

Each `audio` entry:

| Field    | Type              | Required | Description                          |
|----------|-------------------|----------|---------------------------------------|
| `name`   | `string`          | yes      | Track title                           |
| `artist` | `string`          | yes      | Artist name                           |
| `url`    | `string`          | yes      | Audio file URL                        |
| `cover`  | `string \| null`  | no       | Cover image URL                       |
| `lrc`    | `string \| null`  | no       | LRC-formatted lyrics (`[mm:ss.xx]...`) |

## Instance API

Every call to `makePlayer` (JS/TS) or `RPlayer.make` (ReScript) returns an instance you can control programmatically:

| Method (ReScript) | Function (JS/TS)      | Description                                      |
|--------------------|------------------------|---------------------------------------------------|
| `play`             | `playInstance`         | Resume/start playback                              |
| `pause`            | `pauseInstance`        | Pause playback                                     |
| `toggle`           | `toggleInstance`       | Toggle play/pause                                  |
| `next`             | `nextTrack`            | Skip to the next track                             |
| `prev`             | `prevTrack`            | Skip to the previous track                         |
| `seek`             | `seekTo`               | Seek to a given time (seconds)                     |
| `setVolume`        | `setInstanceVolume`    | Set volume (0.0–1.0)                               |
| `toggleList`       | `toggleInstanceList`   | Expand/collapse the playlist panel                 |
| `togglePlayMode`   | `toggleInstanceMode`   | Cycle through list loop / single loop / shuffle     |
| `setColor`         | `setInstanceColor`     | Change the accent color at runtime                 |
| `setTheme`         | `setInstanceTheme`     | Switch between `"light"` / `"dark"` / `"auto"`     |
| `show`             | `showInstance`         | Show the player (undo `hide`)                      |
| `hide`             | `hideInstance`         | Hide the entire player (not just the playlist)      |
| `isHidden`         | `isInstanceHidden`     | Check whether the player is currently hidden        |
| `destroy`          | `destroyInstance`      | Stop playback, clear timers, and remove the DOM     |
| `remount`          | `remountInstance`      | Move the player's DOM into a new container, preserving state |

## Project structure

```text
src/
  Core.res        # Core state machine: playback, playlist, playmode, lyric parsing
  View.res        # HSX-rendered DOM view layer, wires Core state to the DOM
  RPlayer.res     # Public declarative API (RPlayer.make / makePlayer), instance methods, theming
  Icons.res       # Inline SVG icon set
  HSX.res         # Minimal JSX-to-HTML-string renderer (no framework runtime)
  RPlayer.css     # Default styling (CSS custom properties for theming, light/dark support)
  domShims.ts     # genType shim mapping the abstract DOM element type to HTMLElement
  main.js         # Plain-JS usage example / demo page wiring
  Main.res        # ReScript usage example
```

## License

[GPL-3.0-only](./LICENSE)

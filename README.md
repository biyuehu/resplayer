# ResPlayer

A minimal, declarative music player written in [ReScript](https://rescript-lang.org/) — with lyrics scrolling, playlist support, playback-error recovery, and simple theming. Inspired by [APlayer](https://github.com/DIYgod/APlayer)'s configuration style, but rebuilt from scratch as a small, dependency-light state machine plus an HSX-rendered view layer.

Originally a migration of an old vanilla-JS player, ResPlayer keeps the same declarative "just pass a config object" feel while being fully typed and usable from both ReScript and plain JS/TS projects.

## Features

- Declarative configuration, similar to APlayer (`container`, `audio`, `theme`, `fixed`, `autoplay`, `order`, ...)
- Play / pause / prev / next / seek, with a click-to-seek progress bar
- Three playback modes: list loop, single-track loop, and shuffle
- LRC-style lyric parsing with live scrolling, and immediate re-sync on seek
- Automatic skip-to-next on playback error, with a safety stop if every track in the playlist fails
- Optional `fixed` mode to dock the player at the bottom of the page
- One-line theme color override via CSS custom properties
- Usable from ReScript directly, or from plain JavaScript/TypeScript via a generated `.d.ts` (powered by [genType](https://rescript-lang.org/docs/gentype/latest/introduction))

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
import { makeFromJs } from "resplayer/src/RPlayer.res.mjs";
import "resplayer/src/player.css";

makeFromJs({
  container: document.getElementById("aplayer-global"),
  fixed: true,
  autoplay: true,
  order: "random", // "list" | "loop" | "random"
  theme: "#3498db",
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
```

Thanks to genType, TypeScript projects get full type checking and autocomplete on the config object out of the box.

### From ReScript

```res
RPlayer.make({
  container,
  fixed: Some(true),
  autoplay: Some(true),
  order: Some(Random),
  theme: Some("#3498db"),
  audio: [
    {name: "Wake (Live)", artist: "Hillsong Young & Free", url: "...", cover: Some("..."), lrc: Some("...")},
  ],
  titleChange: Some(true),
  showList: Some(false),
  debug: Some(false),
})
```

## Configuration reference

| Field         | Type                              | Default   | Description                                              |
|---------------|------------------------------------|-----------|------------------------------------------------------------|
| `container`   | `HTMLElement`                      | required  | Element the player mounts into                             |
| `audio`       | `Array<{name, artist, url, cover?, lrc?}>` | required  | Playlist                                                    |
| `fixed`       | `boolean`                          | `false`   | Dock the player to the bottom of the viewport               |
| `autoplay`    | `boolean`                          | `false`   | Start playing the first track on mount (desktop only)       |
| `order`       | `"list" \| "loop" \| "random"`     | `"list"`  | Initial playback mode                                       |
| `theme`       | `string` (any CSS color)           | —         | Overrides the player's primary/accent colors                |
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

## Project structure

```text
src/
  Player.res      # Core state machine: playback, playlist, playmode, lyric parsing
  View.res        # HSX-rendered DOM view layer, wires Player state to the DOM
  RPlayer.res     # Public declarative API (RPlayer.make / makeFromJs), theming, fixed mode
  Icons.res       # Inline SVG icon set
  HSX.res         # Minimal JSX-to-HTML-string renderer (no framework runtime)
  player.css      # Default styling (CSS custom properties for theming)
  domShims.ts     # genType shim mapping the abstract DOM element type to HTMLElement
  main.js         # Plain-JS usage example
  Main.res        # ReScript usage example
```

## License

GPL-3.0-only

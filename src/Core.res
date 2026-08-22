module Dom = {
  @genType.import(("./domShims", "HTMLElementT"))
  type element

  type document

  @val external document: document = "document"

  @send external querySelector: (document, string) => Nullable.t<element> = "querySelector"

  @send external querySelectorAll: (document, string) => array<element> = "querySelectorAll"

  @send
  external elQuerySelector: (element, string) => Nullable.t<element> = "querySelector"

  @send
  external elQuerySelectorAll: (element, string) => array<element> = "querySelectorAll"

  @send external addEventListener: (element, string, 'e => unit) => unit = "addEventListener"

  @send
  external removeEventListener: (element, string, 'e => unit) => unit = "removeEventListener"

  @set external setInnerHTML: (element, string) => unit = "innerHTML"

  @get external getInnerHTML: element => string = "innerHTML"

  @send external getBoundingClientRect: element => {..} = "getBoundingClientRect"

  @set external setTextContent: (element, string) => unit = "textContent"

  @send external appendChild: (element, element) => unit = "appendChild"

  @send external remove: element => unit = "remove"

  @get external classList: element => {..} = "classList"

  @get external style: element => {..} = "style"

  // Audio Element

  @new external createAudio: unit => element = "Audio"

  @send external play: element => promise<unit> = "play"

  @send external pause: element => unit = "pause"

  @get external getCurrentTime: element => float = "currentTime"

  @set external setCurrentTime: (element, float) => unit = "currentTime"

  @get external getDuration: element => float = "duration"

  @get external getVolume: element => float = "volume"

  @set external setVolume: (element, float) => unit = "volume"

  @get external getSrc: element => string = "src"

  @set external setSrc: (element, string) => unit = "src"

  @get external getPaused: element => bool = "paused"

  @get external getBuffered: element => {..} = "buffered"

  // window / navigator

  @val external setInterval: (unit => unit, int) => float = "setInterval"

  @val external clearInterval: float => unit = "clearInterval"

  @val external documentObj: {..} = "document"

  @val external navigatorUserAgent: string = "navigator.userAgent"

  let safePlay = (el: element): unit => {
    play(el)->Promise.catch(_ => Promise.resolve())->ignore
  }
}

type track = {
  title: string,
  artist: string,
  link: string,
  cover: option<string>,
  album: option<string>,
  lyric: option<string>,
  subLyric: option<string>,
}

type lyricLine = {
  time: float,
  text: string,
  subText: option<string>,
}

type playMode =
  | Loop
  | Single
  | Random

type playerState = {
  mutable playlist: array<track>,
  mutable randomList: array<track>,
  mutable currentIndex: int,
  mutable lastIndex: int,
  mutable lyrics: array<lyricLine>,
  mutable lyricIndex: int,
  mutable playMode: playMode,
  mutable isPlaying: bool,
  mutable volume: float,
  mutable showList: bool,
  pageTitle: string,
}

module Utils = {
  let parseFileName = (filename: string): (string, string) => {
    let name = filename->String.replaceRegExp(/\.(ogg|mp3|wav|mp4)$/, "")

    let parts = name->String.splitByRegExp(/\s[-–]\s/)

    switch parts {
    | [Some(artist), Some(title)] => (title, artist)

    | _ => (name, "Unknown")
    }
  }

  let formatTime = (seconds: float): string => {
    if Float.isNaN(seconds) {
      "00:00"
    } else {
      let pad = n => n < 10 ? "0" ++ n->Int.toString : n->Int.toString

      let totalSec = seconds->Int.fromFloat

      let hours = totalSec / 3600

      let mins = mod(totalSec, 3600) / 60

      let secs = mod(totalSec, 60)

      hours > 0 ? `${pad(hours)}:${pad(mins)}:${pad(secs)}` : `${pad(mins)}:${pad(secs)}`
    }
  }

  let shuffleArray = (arr: array<'a>): array<'a> => {
    let result = arr->Array.copy

    let len = result->Array.length

    for i in len - 1 downto 1 {
      let j = Js.Math.random_int(0, i + 1)

      let temp = result->Array.getUnsafe(i)

      result->Array.setUnsafe(i, result->Array.getUnsafe(j))

      result->Array.setUnsafe(j, temp)
    }

    result
  }

  let parseLyric = (lyric: string, subLyric: option<string>): array<lyricLine> => {
    if lyric == "" {
      []
    } else {
      let timeMatches = switch lyric->String.match(/\d{2,}:\d{2,}\.\d{1,4}/g) {
      | Some(arr) => arr->Array.filterMap(x => x)
      | None => []
      }

      let textMatches = switch lyric->String.match(/\d{1}\]+.*/g) {
      | Some(arr) => arr->Array.filterMap(x => x)
      | None => []
      }

      let subTextMatches = switch subLyric {
      | Some(s) =>
        switch s->String.match(/\d{1}\]+.*/g) {
        | Some(arr) => Some(arr->Array.filterMap(x => x))
        | None => None
        }
      | None => None
      }

      if timeMatches->Array.length == 0 || timeMatches->Array.length != textMatches->Array.length {
        [{time: 0.0, text: "The lyric does not support scrolling.", subText: None}]
      } else {
        timeMatches->Array.mapWithIndex((timeStr, index) => {
          let parts = timeStr->String.split(":")

          let min = parts->Array.get(0)->Option.flatMap(Float.fromString)->Option.getOr(0.0)

          let sec = parts->Array.get(1)->Option.flatMap(Float.fromString)->Option.getOr(0.0)

          let time = min *. 60.0 +. sec

          let textRaw = textMatches->Array.getUnsafe(index)

          let text = textRaw->String.slice(~start=2, ~end=textRaw->String.length)

          let subText = switch subTextMatches {
          | Some(arr) if arr->Array.length == textMatches->Array.length =>
            Some({
              let s = arr->Array.getUnsafe(index)
              s->String.slice(~start=2, ~end=s->String.length)
            })

          | _ => None
          }

          {time, text, subText}
        })
      }
    }
  }

  let isMobile = (): bool => {
    Dom.navigatorUserAgent->String.toLowerCase->String.includes("mobile")
  }
}

type player = {
  state: playerState,
  audio: Dom.element,
  mutable listItems: array<Dom.element>,
  mutable updateInterval: option<float>,
  mutable onStateChange: unit => unit,
  mutable onTrackChange: unit => unit,
  mutable onSeek: unit => unit,
  mutable errorStreak: int,
}

let make = (playlist: array<track>, ~volume: float=1.0, ()): player => {
  let audio = Dom.createAudio()

  Dom.setVolume(audio, volume)

  let state = {
    playlist,
    randomList: Utils.shuffleArray(playlist),
    currentIndex: 0,
    lastIndex: 0,
    lyrics: [],
    lyricIndex: 0,
    playMode: Loop,
    isPlaying: false,
    volume,
    showList: false,
    pageTitle: Dom.documentObj["title"],
  }

  {
    state,
    audio,
    listItems: [],
    updateInterval: None,
    onStateChange: () => (),
    onTrackChange: () => (),
    onSeek: () => (),
    errorStreak: 0,
  }
}

let notify = (player: player): unit => player.onStateChange()

let getCurrentTrack = (player: player): option<track> =>
  player.state.playlist->Array.get(player.state.currentIndex)

let updateTitle = (player: player, ~isPlaying: bool, ~titleChange: bool): unit => {
  if titleChange {
    switch getCurrentTrack(player) {
    | Some(track) if isPlaying =>
      Dom.documentObj["title"] = "▶ " ++ track.title ++ " - " ++ player.state.pageTitle

    | _ => Dom.documentObj["title"] = player.state.pageTitle
    }
  }
}

let jump = (player: player, index: int): unit => {
  switch player.state.playlist->Array.get(index) {
  | None => ()

  | Some(track) => {
      player.state.currentIndex = index

      player.state.lyricIndex = 0

      player.errorStreak = 0

      Dom.setSrc(player.audio, track.link)

      Dom.safePlay(player.audio)

      player.state.lyrics = Utils.parseLyric(track.lyric->Option.getOr(""), track.subLyric)

      switch player.listItems->Array.get(player.state.lastIndex) {
      | Some(el) => Dom.classList(el)["remove"]("current")

      | None => ()
      }

      switch player.listItems->Array.get(index) {
      | Some(el) => Dom.classList(el)["add"]("current")

      | None => ()
      }

      player.state.lastIndex = index

      player.onTrackChange()
    }
  }
}

let play = (player: player): unit => {
  if Dom.getSrc(player.audio) != "" {
    Dom.safePlay(player.audio)
  }
}

let pause = (player: player): unit => {
  if Dom.getSrc(player.audio) != "" {
    Dom.pause(player.audio)
  }
}

let toggle = (player: player): unit => {
  if Dom.getSrc(player.audio) == "" {
    jump(player, player.state.currentIndex)
  } else if Dom.getPaused(player.audio) {
    play(player)
  } else {
    pause(player)
  }
}

let prev = (player: player): unit => {
  let len = player.state.playlist->Array.length

  if len > 0 {
    let nextIndex = switch player.state.playMode {
    | Random =>
      switch getCurrentTrack(player) {
      | None => 0

      | Some(cur) => {
          let currentInRandom = player.state.randomList->Array.indexOf(cur)

          let prevInRandom =
            currentInRandom <= 0 ? player.state.randomList->Array.length - 1 : currentInRandom - 1

          switch player.state.randomList->Array.get(prevInRandom) {
          | Some(t) => player.state.playlist->Array.indexOf(t)

          | None => 0
          }
        }
      }

    | _ => player.state.currentIndex == 0 ? len - 1 : player.state.currentIndex - 1
    }

    jump(player, nextIndex)
  }
}

let next = (player: player): unit => {
  let len = player.state.playlist->Array.length

  if len > 0 {
    let nextIndex = switch player.state.playMode {
    | Random =>
      switch getCurrentTrack(player) {
      | None => 0

      | Some(cur) => {
          let currentInRandom = player.state.randomList->Array.indexOf(cur)

          let nextInRandom = mod(currentInRandom + 1, player.state.randomList->Array.length)

          switch player.state.randomList->Array.get(nextInRandom) {
          | Some(t) => player.state.playlist->Array.indexOf(t)

          | None => 0
          }
        }
      }

    | _ => mod(player.state.currentIndex + 1, len)
    }

    jump(player, nextIndex)
  }
}

let findLyricIndex = (lyrics: array<lyricLine>, time: float): int => {
  let idx = ref(0)
  lyrics->Array.forEachWithIndex((line, i) => {
    if time >= line.time {
      idx := i
    }
  })
  idx.contents
}

let seek = (player: player, time: float): unit => {
  Dom.setCurrentTime(player.audio, time)

  if player.state.lyrics->Array.length > 0 {
    let idx = findLyricIndex(player.state.lyrics, time)
    player.state.lyricIndex = idx
    player.onSeek()
  }
}

let setVolume = (player: player, volume: float): unit => {
  let vol = volume->Math.max(0.0)->Math.min(1.0)

  player.state.volume = vol

  Dom.setVolume(player.audio, vol)

  notify(player)
}

let togglePlayMode = (player: player): unit => {
  let nextMode = switch player.state.playMode {
  | Loop => Single

  | Single => Random

  | Random => Loop
  }

  player.state.playMode = nextMode

  if nextMode == Random {
    player.state.randomList = Utils.shuffleArray(player.state.playlist)
  }

  notify(player)
}

let toggleVolumeStep = (player: player): unit => {
  let volumes = [1.0, 0.75, 0.5, 0.25]

  let currentIdx = volumes->Array.findIndex(v => Math.abs(v -. player.state.volume) < 0.001)

  let nextIdx = mod((currentIdx < 0 ? 0 : currentIdx) + 1, volumes->Array.length)

  setVolume(player, volumes->Array.getUnsafe(nextIdx))
}

let handlePlaybackError = (player: player): unit => {
  player.errorStreak = player.errorStreak + 1

  let total = player.state.playlist->Array.length

  if total > 0 && player.errorStreak < total {
    next(player)
  } else {
    pause(player)
  }
}

let toggleList = (player: player): unit => {
  player.state.showList = !player.state.showList

  notify(player)
}

let destroy = (player: player): unit => {
  pause(player)

  switch player.updateInterval {
  | Some(id) => Dom.clearInterval(id)

  | None => ()
  }

  player.updateInterval = None

  Dom.setSrc(player.audio, "")
}

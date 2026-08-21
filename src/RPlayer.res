type order =
  | ListOrder
  | Loop
  | Random

type audioItem = {
  name: string,
  artist: string,
  url: string,
  cover: option<string>,
  lrc: option<string>,
}

type config = {
  container: Player.Dom.element,
  fixed: option<bool>,
  autoplay: option<bool>,
  order: option<order>,
  theme: option<string>,
  audio: array<audioItem>,
  titleChange: option<bool>,
  showList: option<bool>,
  debug: option<bool>,
}

@genType.opaque
type instance = {
  player: Player.player,
  handles: View.handles,
}

let toTrack = (item: audioItem): Player.track => {
  title: item.name,
  artist: item.artist,
  link: item.url,
  cover: item.cover,
  album: None,
  lyric: item.lrc,
  subLyric: None,
}

let applyTheme = (container: Player.Dom.element, theme: option<string>): unit => {
  switch theme {
  | Some(color) => {
      let style = Player.Dom.style(container)
      ignore(style["setProperty"]("--rp-primary", color))
      ignore(style["setProperty"]("--rp-accent", color))
    }
  | None => ()
  }
}

let applyFixed = (container: Player.Dom.element, fixed: option<bool>): unit => {
  let classList = Player.Dom.classList(container)
  switch fixed {
  | Some(true) => classList["add"]("rp-fixed")
  | _ => classList["remove"]("rp-fixed")
  }
}

let make = (config: config): instance => {
  let tracks = config.audio->Array.map(toTrack)

  let player = Player.make(tracks, ~volume=1.0, ())

  switch config.order {
  | Some(ListOrder) => player.state.playMode = Loop
  | Some(Loop) => player.state.playMode = Single
  | Some(Random) => {
      player.state.playMode = Random
      player.state.randomList = Player.Utils.shuffleArray(player.state.playlist)
    }
  | None => ()
  }

  let handles = View.attach(
    player,
    config.container,
    ~titleChange=config.titleChange->Option.getOr(true),
    ~debug=config.debug->Option.getOr(false),
    (),
  )

  applyTheme(handles.root, config.theme)
  applyFixed(handles.root, config.fixed)

  if config.showList->Option.getOr(false) {
    Player.toggleList(player)
  }

  if config.autoplay->Option.getOr(false) && !Player.Utils.isMobile() && tracks->Array.length > 0 {
    Player.jump(player, 0)
  }

  {player, handles}
}

@genType
type jsAudioItem = {
  name: string,
  artist: string,
  url: string,
  cover: Nullable.t<string>,
  lrc: Nullable.t<string>,
}

@genType
type jsConfig = {
  container: Player.Dom.element,
  fixed: Nullable.t<bool>,
  autoplay: Nullable.t<bool>,
  order: Nullable.t<string>,
  theme: Nullable.t<string>,
  audio: array<jsAudioItem>,
  titleChange: Nullable.t<bool>,
  showList: Nullable.t<bool>,
  debug: Nullable.t<bool>,
}

let orderFromString = (s: option<string>): option<order> =>
  switch s {
  | Some("random") => Some(Random)
  | Some("loop") => Some(Loop)
  | Some("list") => Some(ListOrder)
  | _ => None
  }

let nullableToOption = (n: Nullable.t<'a>): option<'a> =>
  switch n {
  | Value(v) => Some(v)
  | Null | Undefined => None
  }

@genType
let makeFromJs = (jsConfig: jsConfig): instance => {
  let audio: array<audioItem> = jsConfig.audio->Array.map((item): audioItem => {
    name: item.name,
    artist: item.artist,
    url: item.url,
    cover: item.cover->nullableToOption,
    lrc: item.lrc->nullableToOption,
  })

  make({
    container: jsConfig.container,
    fixed: jsConfig.fixed->nullableToOption,
    autoplay: jsConfig.autoplay->nullableToOption,
    order: jsConfig.order->nullableToOption->orderFromString,
    theme: jsConfig.theme->nullableToOption,
    audio,
    titleChange: jsConfig.titleChange->nullableToOption,
    showList: jsConfig.showList->nullableToOption,
    debug: jsConfig.debug->nullableToOption,
  })
}

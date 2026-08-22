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

type theme =
  | Light
  | Dark
  | Auto

type config = {
  container: Core.Dom.element,
  fixed: option<bool>,
  autoplay: option<bool>,
  order: option<order>,
  color: option<string>,
  theme: option<theme>,
  audio: array<audioItem>,
  titleChange: option<bool>,
  showList: option<bool>,
  debug: option<bool>,
}

@genType.opaque
type playerInstance = {
  player: Core.player,
  handles: View.handles,
}

let toTrack = (item: audioItem): Core.track => {
  title: item.name,
  artist: item.artist,
  link: item.url,
  cover: item.cover,
  album: None,
  lyric: item.lrc,
  subLyric: None,
}

let applyColor = (container: Core.Dom.element, color: option<string>): unit => {
  switch color {
  | Some(c) => {
      let style = Core.Dom.style(container)
      ignore(style["setProperty"]("--rp-primary", c))
      ignore(style["setProperty"]("--rp-accent", c))
    }
  | None => ()
  }
}

let applyFixed = (container: Core.Dom.element, fixed: option<bool>): unit => {
  let classList = Core.Dom.classList(container)
  switch fixed {
  | Some(true) => classList["add"]("rp-fixed")
  | _ => classList["remove"]("rp-fixed")
  }
}

type mediaQueryList = {matches: bool}

@val external matchMedia: string => mediaQueryList = "window.matchMedia"

let prefersDarkColorScheme = (): bool => matchMedia("(prefers-color-scheme: dark)").matches

let applyTheme = (container: Core.Dom.element, theme: option<theme>): unit => {
  let classList = Core.Dom.classList(container)
  ignore(classList["remove"]("rp-dark"))
  ignore(classList["remove"]("rp-light"))

  switch theme {
  | Some(Dark) => classList["add"]("rp-dark")
  | Some(Light) => classList["add"]("rp-light")
  | Some(Auto) =>
    prefersDarkColorScheme() ? classList["add"]("rp-dark") : classList["add"]("rp-light")
  | None => ()
  }
}

let make = (config: config): playerInstance => {
  let tracks = config.audio->Array.map(toTrack)

  let player = Core.make(tracks, ~volume=1.0, ())

  switch config.order {
  | Some(ListOrder) => player.state.playMode = Loop
  | Some(Loop) => player.state.playMode = Single
  | Some(Random) => {
      player.state.playMode = Random
      player.state.randomList = Core.Utils.shuffleArray(player.state.playlist)
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

  applyColor(handles.root, config.color)
  applyFixed(handles.root, config.fixed)
  applyTheme(handles.root, config.theme)

  if config.showList->Option.getOr(false) {
    Core.toggleList(player)
  }

  if config.autoplay->Option.getOr(false) && !Core.Utils.isMobile() && tracks->Array.length > 0 {
    Core.jump(player, 0)
  }

  {player, handles}
}

// ============ Instance methods ============
let play = (instance: playerInstance): unit => Core.play(instance.player)
let pause = (instance: playerInstance): unit => Core.pause(instance.player)
let toggle = (instance: playerInstance): unit => Core.toggle(instance.player)
let next = (instance: playerInstance): unit => Core.next(instance.player)
let prev = (instance: playerInstance): unit => Core.prev(instance.player)
let seek = (instance: playerInstance, time: float): unit => Core.seek(instance.player, time)
let setVolume = (instance: playerInstance, volume: float): unit =>
  Core.setVolume(instance.player, volume)
let toggleList = (instance: playerInstance): unit => Core.toggleList(instance.player)
let togglePlayMode = (instance: playerInstance): unit => Core.togglePlayMode(instance.player)

let setColor = (instance: playerInstance, color: string): unit =>
  applyColor(instance.handles.root, Some(color))

let setTheme = (instance: playerInstance, mode: theme): unit =>
  applyTheme(instance.handles.root, Some(mode))

// 隐藏/显示整个播放器（区别于播放列表的折叠）
let hide = (instance: playerInstance): unit => {
  let classList = Core.Dom.classList(instance.handles.root)
  ignore(classList["add"]("rp-hidden"))
}

let show = (instance: playerInstance): unit => {
  let classList = Core.Dom.classList(instance.handles.root)
  ignore(classList["remove"]("rp-hidden"))
}

let isHidden = (instance: playerInstance): bool => {
  let classList = Core.Dom.classList(instance.handles.root)
  (classList["contains"]("rp-hidden"): bool)
}

let destroy = (instance: playerInstance): unit => {
  Core.destroy(instance.player)
  Core.Dom.remove(instance.handles.root)
}

// 将播放器整体（DOM 节点、内部状态、事件绑定）迁移到新的容器下，
// 不重建实例，播放进度/歌词/播放列表状态都会保留
let remount = (instance: playerInstance, newContainer: Core.Dom.element): unit => {
  Core.Dom.appendChild(newContainer, instance.handles.root)
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
  container: Core.Dom.element,
  fixed: Nullable.t<bool>,
  autoplay: Nullable.t<bool>,
  order: Nullable.t<string>,
  color: Nullable.t<string>,
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

let themeFromString = (s: option<string>): option<theme> =>
  switch s {
  | Some("dark") => Some(Dark)
  | Some("light") => Some(Light)
  | Some("auto") => Some(Auto)
  | _ => None
  }

let nullableToOption = (n: Nullable.t<'a>): option<'a> =>
  switch n {
  | Value(v) => Some(v)
  | Null | Undefined => None
  }

@genType
let makePlayer = (jsConfig: jsConfig): playerInstance => {
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
    color: jsConfig.color->nullableToOption,
    theme: jsConfig.theme->nullableToOption->themeFromString,
    audio,
    titleChange: jsConfig.titleChange->nullableToOption,
    showList: jsConfig.showList->nullableToOption,
    debug: jsConfig.debug->nullableToOption,
  })
}

// ============ genType-exported instance methods (for JS/TS callers) ============
@genType
let playInstance = play
@genType
let pauseInstance = pause
@genType
let toggleInstance = toggle
@genType
let nextTrack = next
@genType
let prevTrack = prev
@genType
let seekTo = seek
@genType
let setInstanceVolume = setVolume
@genType
let toggleInstanceList = toggleList
@genType
let toggleInstanceMode = togglePlayMode
@genType
let setInstanceColor = setColor
@genType
let setInstanceTheme = (instance: playerInstance, mode: string): unit =>
  switch themeFromString(Some(mode)) {
  | Some(m) => setTheme(instance, m)
  | None => ()
  }
@genType
let showInstance = show
@genType
let hideInstance = hide
@genType
let isInstanceHidden = isHidden
@genType
let destroyInstance = destroy
@genType
let remountInstance = remount

open Core

let skeleton = () => {
  open HSX
  <div class="rp-player">
    <div class="rp-header">
      <div class="rp-cover"> {string("")} </div>
      <div class="rp-time"> {string("00:00")} </div>
      <div class="rp-info">
        <span class="rp-title"> {string("Welcome to use ResPlayer")} </span>
        <span class="rp-artist"> {string("Modern Player")} </span>
      </div>
      <div class="rp-controls">
        <div class="rp-btn rp-prev"> {string(Icons.left)} </div>
        <div class="rp-btn rp-toggle"> {string(Icons.play)} </div>
        <div class="rp-btn rp-next"> {string(Icons.right)} </div>
      </div>
      <div class="rp-settings">
        <div class="rp-set rp-volume"> {string(Icons.volumeMax)} </div>
        <div class="rp-set rp-mode"> {string(Icons.loopAll)} </div>
        <div class="rp-set rp-list"> {string(Icons.listIcon)} </div>
      </div>
      <div class="rp-bar">
        <div class="rp-loaded" />
        <div class="rp-played" />
      </div>
    </div>
    <div class="rp-playlist" />
    <div class="rp-lyrics">
      <span> {string("Welcome to use ResPlayer")} </span>
    </div>
  </div>
}

type handles = {
  root: Core.Dom.element,
  cover: Core.Dom.element,
  time: Core.Dom.element,
  title: Core.Dom.element,
  artist: Core.Dom.element,
  btnPrev: Core.Dom.element,
  btnToggle: Core.Dom.element,
  btnNext: Core.Dom.element,
  setVolume: Core.Dom.element,
  setMode: Core.Dom.element,
  setList: Core.Dom.element,
  bar: Core.Dom.element,
  loaded: Core.Dom.element,
  played: Core.Dom.element,
  playlist: Core.Dom.element,
  lyric: Core.Dom.element,
}

let qs = (root: Core.Dom.element, sel: string): Core.Dom.element =>
  switch Core.Dom.elQuerySelector(root, sel) {
  | Value(el) => el
  | Null | Undefined => JsError.throwWithMessage(`View.qs: element not found for "${sel}"`)
  }

let mount = (container: Core.Dom.element): handles => {
  Core.Dom.setInnerHTML(container, skeleton()->HSX.Elements.elementToString)
  let root = qs(container, ".rp-player")

  {
    root,
    cover: qs(container, ".rp-cover"),
    time: qs(container, ".rp-time"),
    title: qs(container, ".rp-title"),
    artist: qs(container, ".rp-artist"),
    btnPrev: qs(container, ".rp-prev"),
    btnToggle: qs(container, ".rp-toggle"),
    btnNext: qs(container, ".rp-next"),
    setVolume: qs(container, ".rp-volume"),
    setMode: qs(container, ".rp-mode"),
    setList: qs(container, ".rp-list"),
    bar: qs(container, ".rp-bar"),
    loaded: qs(container, ".rp-loaded"),
    played: qs(container, ".rp-played"),
    playlist: qs(container, ".rp-playlist"),
    lyric: qs(container, ".rp-lyrics span"),
  }
}

let renderPlaylistItem = (track: Core.track, index: int): string => {
  open HSX
  <div class="rp-item">
    <span class="rp-item-num"> {string((index + 1)->Int.toString)} </span>
    <span class="rp-item-title"> {string(track.title)} </span>
    <span class="rp-item-artist"> {string(track.artist)} </span>
  </div>->HSX.Elements.elementToString
}

let buildPlaylist = (player: Core.player, h: handles): unit => {
  let html =
    player.state.playlist
    ->Array.mapWithIndex((track, index) => renderPlaylistItem(track, index))
    ->Array.join("")

  Core.Dom.setInnerHTML(h.playlist, html)
  player.listItems = Core.Dom.querySelectorAll(Core.Dom.document, ".rp-item")

  player.listItems->Array.forEachWithIndex((item, index) => {
    Core.Dom.addEventListener(item, "click", (_: Core.Dom.element) => {
      if player.state.currentIndex == index && Core.Dom.getSrc(player.audio) != "" {
        Core.toggle(player)
      } else {
        Core.jump(player, index)
      }
    })
  })
}

let renderTrackInfo = (player: Core.player, h: handles): unit => {
  switch Core.getCurrentTrack(player) {
  | Some(track) => {
      Core.Dom.setTextContent(h.title, track.title)
      Core.Dom.setTextContent(h.artist, track.artist)
      let bg = switch track.cover {
      | Some(url) => `url('${url}')`
      | None => ""
      }
      Core.Dom.style(h.cover)["backgroundImage"] = bg
    }
  | None => ()
  }
}

let renderToggleIcon = (h: handles, isPlaying: bool): unit =>
  Core.Dom.setInnerHTML(h.btnToggle, isPlaying ? Icons.pause : Icons.play)

let renderModeIcon = (h: handles, mode: Core.playMode): unit => {
  let icon = switch mode {
  | Loop => Icons.loopAll
  | Single => Icons.loopSingle
  | Random => Icons.random
  }
  Core.Dom.setInnerHTML(h.setMode, icon)
}

let renderVolumeIcon = (h: handles, volume: float): unit => {
  let icon =
    volume >= 0.9
      ? Icons.volumeMax
      : volume >= 0.6
      ? Icons.volumeMid
      : volume >= 0.3
      ? Icons.volumeLow
      : Icons.volumeNone
  Core.Dom.setInnerHTML(h.setVolume, icon)
}

let renderListToggle = (h: handles, show: bool): unit => {
  let classList = Core.Dom.classList(h.playlist)
  show ? classList["add"]("show") : classList["remove"]("show")
}

let renderLyricLine = (h: handles, line: Core.lyricLine): unit =>
  switch line.subText {
  | Some(sub) => Core.Dom.setInnerHTML(h.lyric, line.text ++ "<br><br>" ++ sub)
  | None => Core.Dom.setTextContent(h.lyric, line.text)
  }

let renderLyricPlaceholder = (h: handles, player: Core.player): unit => {
  if player.state.lyrics->Array.length == 0 {
    Core.Dom.setTextContent(h.lyric, "No lyrics available...")
  } else {
    switch Core.getCurrentTrack(player) {
    | Some(track) => Core.Dom.setTextContent(h.lyric, `${track.title} (${track.artist})`)
    | None => ()
    }
  }
}

let renderCurrentLyricLine = (h: handles, player: Core.player): unit => {
  switch player.state.lyrics->Array.get(player.state.lyricIndex) {
  | Some(line) => renderLyricLine(h, line)
  | None => renderLyricPlaceholder(h, player)
  }
}

let updateProgress = (player: Core.player, h: handles): unit => {
  let cur = Core.Dom.getCurrentTime(player.audio)
  let dur = Core.Dom.getDuration(player.audio)
  let percent = dur > 0.0 && !Float.isNaN(dur) ? cur /. dur *. 100.0 : 0.0

  Core.Dom.style(h.played)["width"] = `${percent->Float.toString}%`
  Core.Dom.setTextContent(h.time, Core.Utils.formatTime(cur))
}

let updateLyricPlaying = (player: Core.player, h: handles): unit => {
  if player.state.lyrics->Array.length > 0 {
    switch player.state.lyrics->Array.get(player.state.lyricIndex) {
    | Some(line) if Core.Dom.getCurrentTime(player.audio) >= line.time => {
        renderLyricLine(h, line)
        player.state.lyricIndex = player.state.lyricIndex + 1
      }
    | _ => ()
    }
  }
}

let bindAudioEvents = (player: Core.player, h: handles, ~titleChange: bool, ~debug: bool): unit => {
  Core.Dom.addEventListener(player.audio, "play", (_: Core.Dom.element) => {
    player.state.isPlaying = true
    renderToggleIcon(h, true)
    Core.updateTitle(player, ~isPlaying=true, ~titleChange)

    switch player.updateInterval {
    | Some(_) => ()
    | None => {
        let id = Core.Dom.setInterval(() => {
          updateProgress(player, h)
          updateLyricPlaying(player, h)
        }, 200)
        player.updateInterval = Some(id)
      }
    }
  })

  Core.Dom.addEventListener(player.audio, "pause", (_: Core.Dom.element) => {
    player.state.isPlaying = false
    renderToggleIcon(h, false)
    Core.updateTitle(player, ~isPlaying=false, ~titleChange)

    switch player.updateInterval {
    | Some(id) => {
        Core.Dom.clearInterval(id)
        player.updateInterval = None
      }
    | None => ()
    }
  })

  Core.Dom.addEventListener(player.audio, "progress", (_: Core.Dom.element) => {
    let buffered = Core.Dom.getBuffered(player.audio)
    let length = buffered["length"]
    if length > 0 {
      let dur = Core.Dom.getDuration(player.audio)
      if !Float.isNaN(dur) && dur > 0.0 {
        let endTime = buffered["end"](length - 1)
        let percent = endTime /. dur *. 100.0
        Core.Dom.style(h.loaded)["width"] = `${percent->Float.toString}%`
      }
    }
  })

  Core.Dom.addEventListener(player.audio, "error", (_: Core.Dom.element) => {
    Core.Dom.setTextContent(h.title, ":(")
    Core.Dom.setTextContent(h.artist, "Occurred an error and playing next one...")
    Core.handlePlaybackError(player)
  })

  Core.Dom.addEventListener(player.audio, "ended", (_: Core.Dom.element) => {
    switch player.state.playMode {
    | Single => {
        Core.Dom.setCurrentTime(player.audio, 0.0)
        Core.play(player)
      }
    | _ => Core.next(player)
    }
  })

  ignore(debug)
}

let bindControlEvents = (player: Core.player, h: handles): unit => {
  Core.Dom.addEventListener(h.btnToggle, "click", (_: Core.Dom.element) => Core.toggle(player))
  Core.Dom.addEventListener(h.btnPrev, "click", (_: Core.Dom.element) => Core.prev(player))
  Core.Dom.addEventListener(h.btnNext, "click", (_: Core.Dom.element) => Core.next(player))

  Core.Dom.addEventListener(h.setMode, "click", (_: Core.Dom.element) =>
    Core.togglePlayMode(player)
  )
  Core.Dom.addEventListener(h.setList, "click", (_: Core.Dom.element) => Core.toggleList(player))
  Core.Dom.addEventListener(h.setVolume, "click", (_: Core.Dom.element) =>
    Core.toggleVolumeStep(player)
  )

  Core.Dom.addEventListener(h.bar, "click", (evt: Core.Dom.element) => {
    let dur = Core.Dom.getDuration(player.audio)
    if !Float.isNaN(dur) && dur > 0.0 {
      let rect = Core.Dom.getBoundingClientRect(h.bar)
      let clientX = (Obj.magic(evt): {..})["clientX"]
      let percent = (clientX -. rect["left"]) /. rect["width"]
      Core.seek(player, percent *. dur)
    }
  })
}

let renderAll = (player: Core.player, h: handles): unit => {
  renderTrackInfo(player, h)
  renderToggleIcon(h, player.state.isPlaying)
  renderModeIcon(h, player.state.playMode)
  renderVolumeIcon(h, player.state.volume)
  renderListToggle(h, player.state.showList)
}

let renderOnTrackChange = (player: Core.player, h: handles): unit => {
  renderAll(player, h)
  renderLyricPlaceholder(h, player)
}

let attach = (
  player: Core.player,
  container: Core.Dom.element,
  ~titleChange: bool=true,
  ~debug: bool=false,
  (),
): handles => {
  let h = mount(container)

  buildPlaylist(player, h)
  bindAudioEvents(player, h, ~titleChange, ~debug)
  bindControlEvents(player, h)

  player.onStateChange = () => renderAll(player, h)
  player.onTrackChange = () => renderOnTrackChange(player, h)
  player.onSeek = () => {
    renderAll(player, h)
    renderCurrentLyricLine(h, player)
  }

  renderOnTrackChange(player, h)

  h
}

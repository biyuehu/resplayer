open Player

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
  root: Player.Dom.element,
  cover: Player.Dom.element,
  time: Player.Dom.element,
  title: Player.Dom.element,
  artist: Player.Dom.element,
  btnPrev: Player.Dom.element,
  btnToggle: Player.Dom.element,
  btnNext: Player.Dom.element,
  setVolume: Player.Dom.element,
  setMode: Player.Dom.element,
  setList: Player.Dom.element,
  bar: Player.Dom.element,
  loaded: Player.Dom.element,
  played: Player.Dom.element,
  playlist: Player.Dom.element,
  lyric: Player.Dom.element,
}

let qs = (root: Player.Dom.element, sel: string): Player.Dom.element =>
  switch Player.Dom.elQuerySelector(root, sel) {
  | Value(el) => el
  | Null | Undefined => JsError.throwWithMessage(`View.qs: element not found for "${sel}"`)
  }

let mount = (container: Player.Dom.element): handles => {
  Player.Dom.setInnerHTML(container, skeleton()->HSX.Elements.elementToString)
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

let renderPlaylistItem = (track: Player.track, index: int): string => {
  open HSX
  <div class="rp-item">
    <span class="rp-item-num"> {string((index + 1)->Int.toString)} </span>
    <span class="rp-item-title"> {string(track.title)} </span>
    <span class="rp-item-artist"> {string(track.artist)} </span>
  </div>->HSX.Elements.elementToString
}

let buildPlaylist = (player: Player.player, h: handles): unit => {
  let html =
    player.state.playlist
    ->Array.mapWithIndex((track, index) => renderPlaylistItem(track, index))
    ->Array.join("")

  Player.Dom.setInnerHTML(h.playlist, html)
  player.listItems = Player.Dom.querySelectorAll(Player.Dom.document, ".rp-item")

  player.listItems->Array.forEachWithIndex((item, index) => {
    Player.Dom.addEventListener(item, "click", (_: Player.Dom.element) => {
      if player.state.currentIndex == index && Player.Dom.getSrc(player.audio) != "" {
        Player.toggle(player)
      } else {
        Player.jump(player, index)
      }
    })
  })
}

let renderTrackInfo = (player: Player.player, h: handles): unit => {
  switch Player.getCurrentTrack(player) {
  | Some(track) => {
      Player.Dom.setTextContent(h.title, track.title)
      Player.Dom.setTextContent(h.artist, track.artist)
      let bg = switch track.cover {
      | Some(url) => `url('${url}')`
      | None => ""
      }
      Player.Dom.style(h.cover)["backgroundImage"] = bg
    }
  | None => ()
  }
}

let renderToggleIcon = (h: handles, isPlaying: bool): unit =>
  Player.Dom.setInnerHTML(h.btnToggle, isPlaying ? Icons.pause : Icons.play)

let renderModeIcon = (h: handles, mode: Player.playMode): unit => {
  let icon = switch mode {
  | Loop => Icons.loopAll
  | Single => Icons.loopSingle
  | Random => Icons.random
  }
  Player.Dom.setInnerHTML(h.setMode, icon)
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
  Player.Dom.setInnerHTML(h.setVolume, icon)
}

let renderListToggle = (h: handles, show: bool): unit => {
  let classList = Player.Dom.classList(h.playlist)
  show ? classList["add"]("show") : classList["remove"]("show")
}

let renderLyricLine = (h: handles, line: Player.lyricLine): unit =>
  switch line.subText {
  | Some(sub) => Player.Dom.setInnerHTML(h.lyric, line.text ++ "<br><br>" ++ sub)
  | None => Player.Dom.setTextContent(h.lyric, line.text)
  }

let renderLyricPlaceholder = (h: handles, player: Player.player): unit => {
  if player.state.lyrics->Array.length == 0 {
    Player.Dom.setTextContent(h.lyric, "No lyrics available...")
  } else {
    switch Player.getCurrentTrack(player) {
    | Some(track) => Player.Dom.setTextContent(h.lyric, `${track.title} (${track.artist})`)
    | None => ()
    }
  }
}

let renderCurrentLyricLine = (h: handles, player: Player.player): unit => {
  switch player.state.lyrics->Array.get(player.state.lyricIndex) {
  | Some(line) => renderLyricLine(h, line)
  | None => renderLyricPlaceholder(h, player)
  }
}

let updateProgress = (player: Player.player, h: handles): unit => {
  let cur = Player.Dom.getCurrentTime(player.audio)
  let dur = Player.Dom.getDuration(player.audio)
  let percent = dur > 0.0 && !Float.isNaN(dur) ? cur /. dur *. 100.0 : 0.0

  Player.Dom.style(h.played)["width"] = `${percent->Float.toString}%`
  Player.Dom.setTextContent(h.time, Player.Utils.formatTime(cur))
}

let updateLyricPlaying = (player: Player.player, h: handles): unit => {
  if player.state.lyrics->Array.length > 0 {
    switch player.state.lyrics->Array.get(player.state.lyricIndex) {
    | Some(line) if Player.Dom.getCurrentTime(player.audio) >= line.time => {
        renderLyricLine(h, line)
        player.state.lyricIndex = player.state.lyricIndex + 1
      }
    | _ => ()
    }
  }
}

let bindAudioEvents = (
  player: Player.player,
  h: handles,
  ~titleChange: bool,
  ~debug: bool,
): unit => {
  Player.Dom.addEventListener(player.audio, "play", (_: Player.Dom.element) => {
    player.state.isPlaying = true
    renderToggleIcon(h, true)
    Player.updateTitle(player, ~isPlaying=true, ~titleChange)

    switch player.updateInterval {
    | Some(_) => ()
    | None => {
        let id = Player.Dom.setInterval(() => {
          updateProgress(player, h)
          updateLyricPlaying(player, h)
        }, 200)
        player.updateInterval = Some(id)
      }
    }
  })

  Player.Dom.addEventListener(player.audio, "pause", (_: Player.Dom.element) => {
    player.state.isPlaying = false
    renderToggleIcon(h, false)
    Player.updateTitle(player, ~isPlaying=false, ~titleChange)

    switch player.updateInterval {
    | Some(id) => {
        Player.Dom.clearInterval(id)
        player.updateInterval = None
      }
    | None => ()
    }
  })

  Player.Dom.addEventListener(player.audio, "progress", (_: Player.Dom.element) => {
    let buffered = Player.Dom.getBuffered(player.audio)
    let length = buffered["length"]
    if length > 0 {
      let dur = Player.Dom.getDuration(player.audio)
      if !Float.isNaN(dur) && dur > 0.0 {
        let endTime = buffered["end"](length - 1)
        let percent = endTime /. dur *. 100.0
        Player.Dom.style(h.loaded)["width"] = `${percent->Float.toString}%`
      }
    }
  })

  Player.Dom.addEventListener(player.audio, "error", (_: Player.Dom.element) => {
    Player.Dom.setTextContent(h.title, ":(")
    Player.Dom.setTextContent(h.artist, "Occurred an error and playing next one...")
    Player.handlePlaybackError(player)
  })

  Player.Dom.addEventListener(player.audio, "ended", (_: Player.Dom.element) => {
    switch player.state.playMode {
    | Single => {
        Player.Dom.setCurrentTime(player.audio, 0.0)
        Player.play(player)
      }
    | _ => Player.next(player)
    }
  })

  ignore(debug)
}

let bindControlEvents = (player: Player.player, h: handles): unit => {
  Player.Dom.addEventListener(h.btnToggle, "click", (_: Player.Dom.element) =>
    Player.toggle(player)
  )
  Player.Dom.addEventListener(h.btnPrev, "click", (_: Player.Dom.element) => Player.prev(player))
  Player.Dom.addEventListener(h.btnNext, "click", (_: Player.Dom.element) => Player.next(player))

  Player.Dom.addEventListener(h.setMode, "click", (_: Player.Dom.element) =>
    Player.togglePlayMode(player)
  )
  Player.Dom.addEventListener(h.setList, "click", (_: Player.Dom.element) =>
    Player.toggleList(player)
  )
  Player.Dom.addEventListener(h.setVolume, "click", (_: Player.Dom.element) =>
    Player.toggleVolumeStep(player)
  )

  Player.Dom.addEventListener(h.bar, "click", (evt: Player.Dom.element) => {
    let dur = Player.Dom.getDuration(player.audio)
    if !Float.isNaN(dur) && dur > 0.0 {
      let rect = Player.Dom.getBoundingClientRect(h.bar)
      let clientX = (Obj.magic(evt): {..})["clientX"]
      let percent = (clientX -. rect["left"]) /. rect["width"]
      Player.seek(player, percent *. dur)
    }
  })
}

let renderAll = (player: Player.player, h: handles): unit => {
  renderTrackInfo(player, h)
  renderToggleIcon(h, player.state.isPlaying)
  renderModeIcon(h, player.state.playMode)
  renderVolumeIcon(h, player.state.volume)
  renderListToggle(h, player.state.showList)
}

let renderOnTrackChange = (player: Player.player, h: handles): unit => {
  renderAll(player, h)
  renderLyricPlaceholder(h, player)
}

let attach = (
  player: Player.player,
  container: Player.Dom.element,
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

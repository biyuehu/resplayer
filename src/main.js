// main.js - Plain JS/TS usage demo for ResPlayer's public API
import { makePlayer, playInstance, pauseInstance, toggleInstance, nextTrack, prevTrack, toggleInstanceMode, setInstanceTheme, showInstance, hideInstance, isInstanceHidden, destroyInstance } from "./RPlayer.res.js";
import "./RPlayer.css";

const musicList = [
  {
    name: "Wake (Live)",
    artist: "Hillsong Young & Free",
    url: "http://music.163.com/song/media/outer/url?id=33051313.mp3",
    cover: "https://p1.music.126.net/ROu52DfZhbUtYQTt_X8vpg==/109951167557295220.jpg",
    lrc: null,
  },
  {
    name: "白桦林",
    artist: "朴树",
    url: "http://music.163.com/song/media/outer/url?id=5273188.mp3",
    cover: "https://p1.music.126.net/MZ1KYMkmAr-lDkE-ZaMaQg==/109951169026406813.jpg",
    lrc: null,
  },
  {
    name: "忘情水",
    artist: "刘德华",
    url: "http://music.163.com/song/media/outer/url?id=1438246130.mp3",
    cover: "https://p1.music.126.net/rF1VJWsm3dWPugv042j8Bg==/109951164877954978.jpg",
    lrc: null,
  },
];

let instance = makePlayer({
  container: document.getElementById("aplayer-global"),
  fixed: true,
  autoplay: true,
  order: "random",
  color: "#F7DCFF",
  theme: "auto",
  audio: musicList,
  titleChange: true,
  showList: false,
  debug: false,
});

// Wire up the demo control panel
document.getElementById("btn-play").addEventListener("click", () => playInstance(instance));
document.getElementById("btn-pause").addEventListener("click", () => pauseInstance(instance));
document.getElementById("btn-toggle").addEventListener("click", () => toggleInstance(instance));
document.getElementById("btn-next").addEventListener("click", () => nextTrack(instance));
document.getElementById("btn-prev").addEventListener("click", () => prevTrack(instance));
document.getElementById("btn-mode").addEventListener("click", () => toggleInstanceMode(instance));

document.getElementById("btn-light").addEventListener("click", () => setInstanceTheme(instance, "light"));
document.getElementById("btn-dark").addEventListener("click", () => setInstanceTheme(instance, "dark"));
document.getElementById("btn-auto").addEventListener("click", () => setInstanceTheme(instance, "auto"));

document.getElementById("btn-hide-show").addEventListener("click", (e) => {
  if (isInstanceHidden(instance)) {
    showInstance(instance);
    e.target.textContent = "Hide player";
  } else {
    hideInstance(instance);
    e.target.textContent = "Show player";
  }
});

document.getElementById("btn-destroy").addEventListener("click", () => {
  destroyInstance(instance);
  document.getElementById("btn-destroy").disabled = true;
  document.getElementById("btn-destroy").textContent = "Destroyed";
});
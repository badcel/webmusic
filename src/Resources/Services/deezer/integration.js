/*
 *   Copyright (C) 2014, 2015  Marcel Tiede
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//
// General functions needed for minimal integration
//
WebMusicApi.GetReady = function() {
    return dzPlayer.playerLoaded && dzPlayer.getCurrentSong() != null;
};

WebMusicApi.GetArtist = function() {
    return dzPlayer.getCurrentSong().ART_NAME;
};

WebMusicApi.GetTrack = function() {
    return dzPlayer.getCurrentSong().SNG_TITLE;
};

WebMusicApi.GetAlbum = function() {
    return dzPlayer.getCurrentSong().ALB_TITLE;
};

WebMusicApi.GetArtUrl = function() {
    var coverId = dzPlayer.getCurrentSong().ALB_PICTURE;
    return "http://cdn-images.deezer.com/images/cover/" + coverId + "/300x300-000000-80-0-0.jpg";
};

WebMusicApi.GetPlaybackStatus = function() {
    return dzPlayer.isPlaying() ? 1 : 0;
};

WebMusicApi.GetCanGoNext = function() {
    return dzPlayer.getNextSong() != null;
};

WebMusicApi.GetCanGoPrevious = function() {
    return !document.querySelector(".control-prev").hasAttribute("disabled");
};

WebMusicApi.Next = function() {
    dzPlayer.control.nextSong();
};

WebMusicApi.Previous = function() {
    dzPlayer.control.prevSong();
};

WebMusicApi.Stop = function() {
    dzPlayer.control.pause();
};

WebMusicApi.Play = function() {
    dzPlayer.control.play();
};


//
// Necessary functions if shuffle is supported
//
WebMusicApi.CanShuffle = function() {
    return document.querySelector(".control-shuffle") != null;
};

WebMusicApi.GetShuffle = function() {
    return dzPlayer.shuffle;
};

WebMusicApi.ToggleShuffle = function() {
    dzPlayer.control.setShuffle(!dzPlayer.shuffle);
};

//
// Necessary functions if repeat is supported
//
WebMusicApi.CanRepeat = function() {
    return document.querySelector(".control-repeat") != null
            || document.querySelector(".control-repeat-one") != null;
};

WebMusicApi.GetRepeat = function() {
    return dzPlayer.getRepeat();
};

WebMusicApi.SetRepeat = function(status) {
    // 0 = No repeat
    // 1 = Repeat playlist
    // 2 = Repeat track
    dzPlayer.control.setRepeat(status);
};

//
// Necessary functions if like is supported
//
WebMusicApi.GetLike = function() {
    return document.querySelector(".player-actions .icon-love").classList.contains("active");
};

WebMusicApi.ToggleLike = function() {
    document.querySelector(".player-actions .icon-love").parentNode.parentNode.click();
};

//
// Necessary functions if setting volume is supported
//
WebMusicApi.GetVolume = function() {
    return dzPlayer.volume;
};

WebMusicApi.SetVolume = function(volume) {
    dzPlayer.control.setVolume(volume);
};

//
// Necessary functions if seeking is supported
//
WebMusicApi.GetTrackLength = function() {
    return dzPlayer.getCurrentSong().DURATION * 1000000;
};

WebMusicApi.GetTrackPosition = function() {
    return dzPlayer.position * 1000000;
};

WebMusicApi.SetTrackPosition = function(position) {
    var percent = (position/1000000) / dzPlayer.getCurrentSong().DURATION;
    dzPlayer.control.seek(percent);
};


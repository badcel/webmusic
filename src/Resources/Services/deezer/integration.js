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

WebMusicApi.GetReady = function() {
    return dzPlayer.playerLoaded && dzPlayer.getCurrentSong() != null;
};

WebMusicApi.GetArtist = function(){
    return dzPlayer.getCurrentSong().ART_NAME;
};

WebMusicApi.GetTrack = function(){
    return dzPlayer.getCurrentSong().SNG_TITLE;
};

WebMusicApi.GetAlbum = function(){
    return dzPlayer.getCurrentSong().ALB_TITLE;
};

WebMusicApi.GetArtUrl = function(){
    var coverId = dzPlayer.getCurrentSong().ALB_PICTURE;
    return "http://cdn-images.deezer.com/images/cover/" + coverId + "/300x300-000000-80-0-0.jpg";
};

WebMusicApi.GetPlaybackStatus = function(){
    return dzPlayer.isPlaying() ? 1 : 2;
};

WebMusicApi.GetCanGoNext = function(){
    return dzPlayer.getNextSong() != null;
};

WebMusicApi.GetCanGoPrevious = function(){
    return dzPlayer.getPrevSong() != null;
};

WebMusicApi.Next = function(){
    dzPlayer.control.nextSong();
};

WebMusicApi.Previous = function(){
    dzPlayer.control.prevSong();
};

WebMusicApi.Pause = function(){
    dzPlayer.control.pause();
};

WebMusicApi.Play = function(){
    dzPlayer.control.play();
};

WebMusicApi.GetShuffle = function(){
    return dzPlayer.shuffle;
};

WebMusicApi.ToggleShuffle = function() {
    dzPlayer.control.setShuffle(!dzPlayer.shuffle);
};

WebMusicApi.CanShuffle = function() {
    return document.querySelector(".control-shuffle") != null;
};

WebMusicApi.GetLike = function(){
    return document.querySelector(".icon-love-circle").classList.contains("active");
};

WebMusicApi.ToggleLike = function() {
    document.querySelector(".icon-love-circle").click();
};

WebMusicApi.GetLoopStatus = function(){
    return dzPlayer.repeat;
};

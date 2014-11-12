/*
 *   Copyright (C) 2014  Marcel Tiede
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
    return document.contains(document.getElementById("user_logged")) && dzPlayer.getCurrentSong() != null;
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
    return document.getElementById("naboo_menu_infos_cover").src;
};

WebMusicApi.GetPlaybackStatus = function(){
    return dzPlayer.isPlaying() ? 1: 2;
};

WebMusicApi.GetCanGoNext = function(){
    return playercontrol.nextButtonActive();
};

WebMusicApi.GetCanGoPrevious = function(){
    return playercontrol.prevButtonActive();
};

WebMusicApi.Next = function(){
    playercontrol.doAction('next');
};

WebMusicApi.Previous = function(){
    playercontrol.doAction('prev');
};

WebMusicApi.Pause = function(){
    playercontrol.doAction('pause');
};

WebMusicApi.Play = function(){
    playercontrol.doAction('play');
};

WebMusicApi.GetShuffle = function(){
    return dzPlayer.shuffle;
};

WebMusicApi.ToggleShuffle = function() {
    playercontrol.doAction('shuffle');
};

WebMusicApi.CanShuffle = function() {
    return !playercontrol.$btnRandom.hasClass("disabled");
};

WebMusicApi.GetLike = function(){
    return playercontrol.$btnLoved.hasClass("selected");
};

WebMusicApi.ToggleLike = function() {
    playercontrol.$btnLoved.click();
};

WebMusicApi.GetLoopStatus = function(){
    return dzPlayer.repeat;
};

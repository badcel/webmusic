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

"use strict";

(function(WebMusicApi) {

    var PlayerAction = {
        STOP    : "stop",
        PLAY    : "play",
        PAUSE   : "pause",
        NEXT    : "next",
        PREVIOUS: "previous",
        REPEAT  : "repeat",
        VOLUME  : "volume",
        TRACK_POSITION : "track-position",
        TOGGLE_SHUFFLE : "toggle-shuffle",
        TOGGLE_LIKE    : "toggle-like"
    };

    var PlaybackState = {
        STOP : 0,
        PLAY : 1,
        PAUSE: 2,
    };

    WebMusicApi.init = function() {
        WebMusicApi.ready      = false;

        WebMusicApi.canControl = true;
        WebMusicApi.canPlay    = true;
        WebMusicApi.canPause   = false;
        WebMusicApi.canSeek    = true;

        WebMusicApi.update();
    };

    WebMusicApi.update = function() {

        if(!WebMusicApi.ready) {
            WebMusicApi.ready = dzPlayer.playerLoaded && dzPlayer.getCurrentSong() != null;
            setTimeout(this.update.bind(this), 500);
            return;
        }

        let currentSong = dzPlayer.getCurrentSong();

        switch(currentSong.__TYPE__) {
            case 'episode':
                WebMusicApi.url    = 'http://www.deezer.com/show/' + currentSong.SHOW_ID + '#' + currentSong.EPISODE_ID;
                WebMusicApi.artist = currentSong.SHOW_NAME;
                WebMusicApi.track  = currentSong.EPISODE_TITLE;
                WebMusicApi.album  = '';
                WebMusicApi.artUrl = 'http://cdn-images.deezer.com/images/talk/' + currentSong.SHOW_ART_MD5 + '/300x300.jpg';
                break;
            case 'song':
                WebMusicApi.url    = 'http://www.deezer.com/album/' + currentSong.ALB_ID + '#naboo_datagrid_track_' + currentSong.SNG_ID;
                WebMusicApi.artist = currentSong.ART_NAME;
                WebMusicApi.track  = currentSong.SNG_TITLE;
                WebMusicApi.album  = currentSong.ALB_TITLE;
                WebMusicApi.artUrl = 'http://cdn-images.deezer.com/images/cover/' + currentSong.ALB_PICTURE + '/300x300-000000-80-0-0.jpg';
                break;
            default:
                WebMusicApi.warning('Deezer - Unknown type: ' + currentSong.__TYPE__);
        }

        WebMusicApi.playbackStatus = dzPlayer.isPlaying()? PlaybackState.PLAY : PlaybackState.STOP;

        WebMusicApi.canGoNext     = WebMusicApi._isButtonEnabled('next');
        WebMusicApi.canGoPrevious = WebMusicApi._isButtonEnabled('prev');

        WebMusicApi.canShuffle    = WebMusicApi._isButtonPresent('shuffle');
        WebMusicApi.canRepeat     = WebMusicApi._isButtonPresent('repeat') || WebMusicApi._isButtonPresent('repeat-one');

        WebMusicApi.repeat        = dzPlayer.getRepeat();
        WebMusicApi.volume        = dzPlayer.volume;
        WebMusicApi.shuffle       = dzPlayer.shuffle;
        WebMusicApi.like          = document.querySelector('.player-actions .icon-love').classList.contains('active');

        WebMusicApi.trackLength   = currentSong.DURATION * 1000000;
        WebMusicApi.trackPosition = dzPlayer.position * 1000000;

        setTimeout(this.update.bind(this), 500);
    };

    WebMusicApi.ActivateAction = function(action, parameter) {

        switch(action) {
            case PlayerAction.PLAY:
                dzPlayer.control.play();
                break;
            case PlayerAction.STOP:
            case PlayerAction.PAUSE:
                dzPlayer.control.pause();
                break;
            case PlayerAction.NEXT:
                dzPlayer.control.nextSong();
                break;
            case PlayerAction.PREVIOUS:
                dzPlayer.control.prevSong();
                break;
            case PlayerAction.REPEAT:
                dzPlayer.control.setRepeat(parameter);
                break;
            case PlayerAction.VOLUME:
                dzPlayer.control.setVolume(parameter);
                break;
            case PlayerAction.TOGGLE_SHUFFLE:
                dzPlayer.control.setShuffle(!dzPlayer.shuffle);
                break;
            case PlayerAction.TOGGLE_LIKE:
                document.querySelector('.player-actions .icon-love').parentNode.parentNode.click();
                break;
            case PlayerAction.TRACK_POSITION:
                let percent = (parameter / 1000000) / dzPlayer.getCurrentSong().DURATION;
                dzPlayer.control.seek(percent);
                break;
            default:
                WebMusicApi.warning('Deezer - Unknown action: ' + action);
        }
    };

    WebMusicApi._isButtonPresent = function(name) {
        let button = document.querySelector('.player-controls .control-' + name);
        return button != null
    };

    WebMusicApi._isButtonEnabled = function(name) {
        let button = document.querySelector('.player-controls .control-' + name);
        return button == null? false : !button.disabled
    };

})(this);

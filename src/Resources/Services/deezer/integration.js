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

    WebMusicApi.init = function() {
        let player = WebMusicApi.Player;

        player.ready      = false;
        player.canControl = true;
        player.canPlay    = true;
        player.canPause   = false;
        player.canSeek    = true;

        WebMusicApi.update();
    };

    WebMusicApi.update = function() {
        try {
            let player = WebMusicApi.Player;

            if(!player.ready) {
                player.ready = dzPlayer.playerLoaded && dzPlayer.getCurrentSong() != null;
                setTimeout(this.update.bind(this), 500);
                return;
            }

            let currentSong = dzPlayer.getCurrentSong();

            switch(currentSong.__TYPE__) {
                case 'episode':
                    player.url    = 'http://www.deezer.com/show/' + currentSong.SHOW_ID + '#' + currentSong.EPISODE_ID;
                    player.artist = currentSong.SHOW_NAME;
                    player.track  = currentSong.EPISODE_TITLE;
                    player.album  = '';
                    player.artUrl = 'http://cdn-images.deezer.com/images/talk/' + currentSong.SHOW_ART_MD5 + '/300x300.jpg';
                    break;
                case 'song':
                    player.url    = 'http://www.deezer.com/album/' + currentSong.ALB_ID + '#naboo_datagrid_track_' + currentSong.SNG_ID;
                    player.artist = currentSong.ART_NAME;
                    player.track  = currentSong.SNG_TITLE;
                    player.album  = currentSong.ALB_TITLE;
                    player.artUrl = 'http://cdn-images.deezer.com/images/cover/' + currentSong.ALB_PICTURE + '/300x300-000000-80-0-0.jpg';
                    break;
                default:
                    WebMusicApi.warning('Deezer - Unknown type: ' + currentSong.__TYPE__);
            }

            player.playbackStatus = dzPlayer.isPlaying()? player.PlaybackState.PLAY : player.PlaybackState.STOP;

            player.canGoNext     = WebMusicApi._isButtonEnabled('next');
            player.canGoPrevious = WebMusicApi._isButtonEnabled('prev');

            player.canShuffle    = WebMusicApi._isButtonPresent('shuffle');
            player.canRepeat     = WebMusicApi._isButtonPresent('repeat') || WebMusicApi._isButtonPresent('repeat-one');

            player.repeat        = dzPlayer.getRepeat();
            player.volume        = dzPlayer.volume;
            player.shuffle       = dzPlayer.shuffle;
            player.like          = document.querySelector('.player-actions .icon-love').classList.contains('active');

            player.trackLength   = currentSong.DURATION * 1000000;
            player.trackPosition = dzPlayer.position * 1000000;

            player.sendPropertyChange();

        } catch(e) {
            WebMusicApi.warning("Deezer - Error:" + e.message);
        } finally {
            setTimeout(this.update.bind(this), 500);
        }
    };

    WebMusicApi.ActivateAction = function(action, parameter) {
        try {
        let player = WebMusicApi.Player;

        switch(action) {
            case player.Action.PLAY:
                dzPlayer.control.play();
                break;
            case player.Action.STOP:
            case player.Action.PAUSE:
                dzPlayer.control.pause();
                break;
            case player.Action.NEXT:
                dzPlayer.control.nextSong();
                break;
            case player.Action.PREVIOUS:
                dzPlayer.control.prevSong();
                break;
            case player.Action.REPEAT:
                dzPlayer.control.setRepeat(parameter);
                break;
            case player.Action.VOLUME:
                dzPlayer.control.setVolume(parameter);
                break;
            case player.Action.TOGGLE_SHUFFLE:
                dzPlayer.control.setShuffle(!dzPlayer.shuffle);
                break;
            case player.Action.TOGGLE_LIKE:
                document.querySelector('.player-actions .icon-love').parentNode.parentNode.click();
                break;
            case player.Action.TRACK_POSITION:
                let percent = (parameter / 1000000) / dzPlayer.getCurrentSong().DURATION;
                dzPlayer.control.seek(percent);
                break;
            case WebMusicApi.Browser.Action.SEARCH:
                www.navigate('/search/' + parameter);
                break;
            case WebMusicApi.Browser.Action.SHOW:
                let type    = arguments[1];
                let id      = arguments[2];

                let url = '';

                switch(type) {
                    case WebMusicApi.Browser.ActionShowType.TRACK:
                        url = '/track/' + id;
                        break;
                    case WebMusicApi.Browser.ActionShowType.ALBUM:
                        url = '/album/' + id;
                        break;
                    case WebMusicApi.Browser.ActionShowType.ARTIST:
                        url =  '/artist/' + id;
                        break;
                    default:
                        url = '';
                }

                www.navigate(url);
                break;
            default:
                WebMusicApi.warning('Deezer - Unknown action: ' + action);
        }
        } catch(e) {
            WebMusicApi.warning("Deezer - Could not activate action:" + e.message);
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

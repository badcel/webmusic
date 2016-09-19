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

    class DeezerPlayer extends WebMusicApi.BasePlayer {
        constructor() {
            super();

            this.ready      = false;
            this.canControl = true;
            this.canPlay    = true;
            this.canPause   = false;
            this.canSeek    = true;
        }

        update() {
            try {

                if(!this.ready) {
                    this.ready = dzPlayer.playerLoaded && dzPlayer.getCurrentSong() != null;
                    setTimeout(this.update.bind(this), 500);
                    return;
                }

                let currentSong = dzPlayer.getCurrentSong();

                switch(currentSong.__TYPE__) {
                    case 'episode':
                        this.url    = 'http://www.deezer.com/show/' + currentSong.SHOW_ID + '#' + currentSong.EPISODE_ID;
                        this.artist = currentSong.SHOW_NAME;
                        this.track  = currentSong.EPISODE_TITLE;
                        this.album  = '';
                        this.artUrl = 'http://cdn-images.deezer.com/images/talk/' + currentSong.SHOW_ART_MD5 + '/300x300.jpg';
                        break;
                    case 'song':
                        this.url    = 'http://www.deezer.com/album/' + currentSong.ALB_ID + '#naboo_datagrid_track_' + currentSong.SNG_ID;
                        this.artist = currentSong.ART_NAME;
                        this.track  = currentSong.SNG_TITLE;
                        this.album  = currentSong.ALB_TITLE;
                        this.artUrl = 'http://cdn-images.deezer.com/images/cover/' + currentSong.ALB_PICTURE + '/300x300-000000-80-0-0.jpg';
                        break;
                    default:
                        WebMusicApi.warning('Deezer - Unknown type: ' + currentSong.__TYPE__);
                }

                this.playbackStatus = dzPlayer.isPlaying()? this.PlaybackState.PLAY : this.PlaybackState.STOP;

                this.canGoNext     = this._isButtonEnabled('next');
                this.canGoPrevious = this._isButtonEnabled('prev');

                this.canShuffle    = this._isButtonPresent('shuffle');
                this.canRepeat     = this._isButtonPresent('repeat') || this._isButtonPresent('repeat-one');

                this.repeat        = dzPlayer.getRepeat();
                this.volume        = dzPlayer.volume;
                this.shuffle       = dzPlayer.shuffle;
                this.like          = document.querySelector('.player-actions .icon-love').classList.contains('active');

                this.trackLength   = currentSong.DURATION * 1000000;
                this.trackPosition = dzPlayer.position * 1000000;

                this.sendPropertyChange();

            } catch(e) {
                this.warning("Error:" + e.message);
            } finally {
                setTimeout(this.update.bind(this), 500);
            }
        }

        actionPlay() {
            dzPlayer.control.play();
        }

        actionPause() {
            dzPlayer.control.pause();
        }

        actionStop() {
            dzPlayer.control.pause();
        }

        actionNext() {
            dzPlayer.control.nextSong();
        }

        actionPrevious(){
            dzPlayer.control.prevSong();
        }

        actionRepeat(repeatstatus){
            dzPlayer.control.setRepeat(repeatstatus);
        }

        actionVolume(volume){
            dzPlayer.control.setVolume(volume);
        }

        actionToggleShuffle(){
            dzPlayer.control.setShuffle(!dzPlayer.shuffle);
        }

        actionToggleLike() {
           document.querySelector('.player-actions .icon-love').parentNode.parentNode.click();
        }

        actionTrackPosition(position) {
            let percent = (position / 1000000) / dzPlayer.getCurrentSong().DURATION;
            dzPlayer.control.seek(percent);
        }

        actionSearch(searchstring){
            www.navigate('/search/' + searchstring);
        }

        actionShow(type, id){
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
        }

        _isButtonPresent(name) {
            let button = document.querySelector('.player-controls .control-' + name);
            return button != null;
        }

        _isButtonEnabled(name) {
            let button = document.querySelector('.player-controls .control-' + name);
            return button == null? false : !button.disabled;
        }
    }

    WebMusicApi.init = function() {
        WebMusicApi.Player = new DeezerPlayer();
        WebMusicApi.Player.start();
    };

})(this); //WebMusicApi scope

/*
 *   Copyright (C) 2016  Marcel Tiede
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

    let ApiType = {
        PLAYER   : 0,
        PLAYLIST : 1,
        TRACKLIST: 2
    };

    class BaseApi {
        constructor(type) {
            this.type = type;
            this.changes = {};
        }

        start() {
            document.onreadystatechange = function () {
                if (document.readyState === "complete") {
                    this.update();
                }
            }.bind(this);
        }

        update() {
            WebMusicApi.warning("Function update is not available");
        }

        sendPropertyChange() {

            if(Object.keys(this.changes).length > 0) {
                this.debug(JSON.stringify(this.changes));

                WebMusicApi.sendPropertyChange(this.type, this.changes);
                this.changes = {};
            }
        }

        sendSignal(name, params) {
            WebMusicApi.sendSignal(this.type, name, params);
        }

        debug(text) {
            WebMusicApi.debug(this.type, text);
        }

        warning(text) {
            WebMusicApi.warning(this.type, text);
        }
    }

    class BasePlayer extends BaseApi {
        constructor() {
            super(ApiType.PLAYER);

            this._ready = false;

            this._canControl    = false;
            this._canPlay       = false;
            this._canPause      = false;
            this._canSeek       = false;
            this._canGoNext     = false;
            this._canGoPrevious = false;
            this._canShuffle    = false;
            this._canRepeat     = false;

            this._playbackStatus = 0;
            this._repeat         = 0;
            this._volume         = 50;
            this._shuffle        = false;
            this._like           = false;
            this._trackPosition  = 0;

            this._url         = '';
            this._artist      = '';
            this._track       = '';
            this._album       = '';
            this._artUrl      = '';
            this._trackLength = 0;

            this._metadataChanged = false;
        }

        get PlaybackState() {
            return { STOP : 0,
                     PLAY : 1,
                     PAUSE: 2
            };
        }

        /*
         * Defines if the integration script is ready
         * to deliver information (bool)
         */
        set ready(value) {
            if(value != this._ready) {
                this.changes.ready = value;
                this._ready = value;
            }
        }

        get ready() {
            return this._ready;
        }

        /*
         * Most of the following properties correspond to the
         * MPRIS specification of the interface org.mpris.MediaPlayer2.Player.
         *
         * See: https://specifications.freedesktop.org/mpris-spec/latest/Player_Interface.html
         */

        set canControl(value) {
            if(value != this._canControl) {
                this.changes.canControl = value;
                this._canControl = value;
            }
        }

        get canControl() {
            return this._canControl;
        }

        set canPlay(value) {
            if(value != this._canPlay) {
                this.changes.canPlay = value;
                this._canPlay = value;
            }
        }

        get canPlay() {
            return this._canPlay;
        }

        set canPause(value) {
            if(value != this._canPause) {
                this.changes.canPause = value;
                this._canPause = value;
            }
        }

        get canPause() {
            return this._canPause;
        }

        set canSeek(value) {
            if(value != this._canSeek) {
                this.changes.canSeek = value;
                this._canSeek = value;
            }
        }

        get canSeek() {
            return this._canSeek;
        }

        set canGoNext(value) {
            if(value != this._canGoNext) {
                this.changes.canGoNext = value;
                this._canGoNext = value;
            }
        }

        get canGoNext() {
            return this._canGoNext;
        }

        set canGoPrevious(value) {
            if(value != this._canGoPrevious) {
                this.changes.canGoPrevious = value;
                this._canGoPrevious = value;
            }
        }

        get canGoPrevious() {
            return this._canGoPrevious;
        }

        set canShuffle(value) {
            if(value != this._canShuffle) {
                this.changes.canShuffle = value;
                this._canShuffle = value;
            }
        }

        get canShuffle() {
            return this._canShuffle;
        }

        set canRepeat(value) {
            if(value != this._canRepeat) {
                this.changes.canRepeat = value;
                this._canRepeat = value;
            }
        }

        get canRepeat() {
            return this._canRepeat;
        }

        /*
         * playbackStatus uses values of this.PlaybackState
         * See definition vor values.
         */
        set playbackStatus(value) {
            if(value != this._playbackStatus) {
                this.changes.playbackStatus = value;
                this._playbackStatus = value;
            }
        }

        get playbackStatus() {
            return this._playbackStatus;
        }

        /*
         * Corresponds to the LoopStatus property of the MPRIS specification
         *
         * Values:
         *  0: No repeat
         *  1: Repeat playlist
         *  2: Repeat track
         */
        set repeat(value) {
            if(value != this._repeat) {
                this.changes.repeat = value;
                this._repeat = value;
            }
        }

        get repeat() {
            return this._repeat;
        }

        /*
         * Volume is set in percent (0.0 - 1.0)
         */
        set volume(value) {
            if(value != this._volume) {
                this.changes.volume = value;
                this._volume = value;
            }
        }

        get volume() {
            return this._volume;
        }

        set shuffle(value) {
            if(value != this._shuffle) {
                this.changes.shuffle = value;
                this._shuffle = value;
            }
        }

        get shuffle() {
            return this._shuffle;
        }

        /*
         * Mark a song as favourite (bool)
         *
         * Not specified in MPRIS specification
         */
        set like(value) {
            if(value != this._like) {
                this.changes.like = value;
                this._like = value;
            }
        }

        get like() {
            return this._like;
        }

        /*
         * Corresponds to the Position property of the MPRIS specification
         *
         * trackPosition is defined in microseconds
         */
        set trackPosition(value) {
            if(value != this._trackPosition) {

                if(this._trackPosition + 2000000 < value
                    || this._trackPosition - 2000000 > value) {

                    this.sendSignal("seeked", value);
                }

                //According to MPRIS2 spec property changes are not tracked
                this._trackPosition = value;
            }
        }

        get trackPosition() {
            return this._trackPosition;
        }

        /*
         * The following data belongs to the Metadata property
         * of the MPRIS Specification
         */

        /*
         * URL to identify track
         */
        set url(value) {
            if(value != this._url) {
                this._metadataChanged = true;
                this._url = value;
            }
        }

        get url() {
            return this._url;
        }

        set artist(value) {
            if(value != this._artist) {
                this._metadataChanged = true;
                this._artist = value;
            }
        }

        get artist() {
            return this._artist;
        }

        set track(value) {
            if(value != this._track) {
                this._metadataChanged = true;
                this._track = value;
            }
        }

        get track() {
            return this._track;
        }

        set album(value) {
            if(value != this._album) {
                this._metadataChanged = true;
                this._album = value;
            }
        }

        get album() {
            return this._album;
        }

        /*
         * Url of album picture
         */
        set artUrl(value) {
            if(value != this._artUrl) {
                this._metadataChanged = true;
                this._artUrl = value;
            }
        }

        get artUrl() {
            return this._artUrl;
        }

        /*
         * trackLength is specified in microseconds
         */
        set trackLength(value) {
            if(value != this._trackLength) {
                this._metadataChanged = true;
                this._trackLength = value;
            }
        }

        get trackLength() {
            return this._trackLength;
        }

        actionPlay() {
            this.warning("Function actionPlay is not available");
        }

        actionPause() {
            this.warning("Function actionPause is not available");
        }

        actionStop() {
            this.warning("Function actionStop is not available");
        }

        actionNext() {
            this.warning("Function actionNext is not available");
        }

        actionPrevious() {
            this.warning("Function actionPrevious is not available");
        }

        actionRepeat(repeatstatus) {
            this.warning("Function actionRepeat is not available");
        }

        actionVolume(volume) {
            this.warning("Function actionVolume is not available");
        }

        actionToggleShuffle() {
            this.warning("Function actionToggleShuffle is not available");
        }

        actionToggleLike() {
            this.warning("Function actionToggleLike is not available");
        }

        actionTrackPosition(position) {
            this.warning("Function actionTrackPosition is not available");
        }

        actionSearch(searchstring) {
            this.warning("Function actionSearch is not available");
        }

        actionShow(type, id) {
            this.warning("Function actionShow is not available");
        }

        sendPropertyChange() {

            if(this._metadataChanged) {
                //Always send complete metadata
                this.changes.url         = this.url;
                this.changes.artist      = this.artist;
                this.changes.track       = this.track;
                this.changes.album       = this.album;
                this.changes.artUrl      = this.artUrl;
                this.changes.trackLength = this.trackLength;

                this._metadataChanged = false;
            }

            super.sendPropertyChange();
        }
    }

    WebMusicApi.BasePlayer = BasePlayer;

    function Browser() {}
    Browser.prototype.ActionShowType = {
        TRACK    : 'track',
        ALBUM    : 'album',
        ARTIST   : 'artist',
        SHOW     : 'show'
    };

    WebMusicApi.Browser = new Browser();

})(this); //WebMusicApi scope

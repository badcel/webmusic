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

    class BaseApi {
        constructor() {
            this.changes = new Array();
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

        get PropertyChangeType() {
            return { PLAYER   : 0,
                     PLAYLIST : 1,
                     TRACKLIST: 2,
            };
        }

        sendPropertyChange(type) {

            if(this.changes.length > 0) {

                let info = "";
                for(let i = 0; i < this.changes.length; i++) {
                    info += "<" + this.changes[i][0] + ":" + this.changes[i][1] + ">";
                }
                WebMusicApi.debug(info);

                WebMusicApi.sendPropertyChange(type, this.changes);

                this.changes = [];
            }
        }
    }

    class BasePlayer extends BaseApi {
        constructor() {
            super();

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

        get Properties() {
            return { READY           : 'ready',
                     CAN_CONTROL     : 'canControl',
                     CAN_PLAY        : 'canPlay',
                     CAN_PAUSE       : 'canPause',
                     CAN_SEEK        : 'canSeek',
                     CAN_GO_NEXT     : 'canGoNext',
                     CAN_GO_PREVIOUS : 'canGoPrevious',
                     CAN_SHUFFLE     : 'canShuffle',
                     CAN_REPEAT      : 'canRepeat',
                     URL             : 'url',
                     ARTIST          : 'artist',
                     TRACK           : 'track',
                     ALBUM           : 'album',
                     ART_URL         : 'artUrl',
                     PLAYBACKSTATUS  : 'playbackstatus',
                     LIKE            : 'like',
                     SHUFFLE         : 'shuffle',
                     REPEAT          : 'repeat',
                     VOLUME          : 'volume',
                     TRACK_LENGTH    : 'trackLength',
                     TRACK_POSITION  : 'trackPosition'
            };
        }

        /*
         * Defines if the integration script is ready
         * to deliver information (bool)
         */
        set ready(value) {
            if(value != this._ready) {
                this.changes.push([this.Properties.READY, value]);
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
                this.changes.push([this.Properties.CAN_CONTROL, value]);
                this._canControl = value;
            }
        }

        get canControl() {
            return this._canControl;
        }

        set canPlay(value) {
            if(value != this._canPlay) {
                this.changes.push([this.Properties.CAN_PLAY, value]);
                this._canPlay = value;
            }
        }

        get canPlay() {
            return this._canPlay;
        }

        set canPause(value) {
            if(value != this._canPause) {
                this.changes.push([this.Properties.CAN_PAUSE, value]);
                this._canPause = value;
            }
        }

        get canPause() {
            return this._canPause;
        }

        set canSeek(value) {
            if(value != this._canSeek) {
                this.changes.push([this.Properties.CAN_SEEK, value]);
                this._canSeek = value;
            }
        }

        get canSeek() {
            return this._canSeek;
        }

        set canGoNext(value) {
            if(value != this._canGoNext) {
                this.changes.push([this.Properties.CAN_GO_NEXT, value]);
                this._canGoNext = value;
            }
        }

        get canGoNext() {
            return this._canGoNext;
        }

        set canGoPrevious(value) {
            if(value != this._canGoPrevious) {
                this.changes.push([this.Properties.CAN_GO_PREVIOUS, value]);
                this._canGoPrevious = value;
            }
        }

        get canGoPrevious() {
            return this._canGoPrevious;
        }

        set canShuffle(value) {
            if(value != this._canShuffle) {
                this.changes.push([this.Properties.CAN_SHUFFLE, value]);
                this._canShuffle = value;
            }
        }

        get canShuffle() {
            return this._canShuffle;
        }

        set canRepeat(value) {
            if(value != this._canRepeat) {
                this.changes.push([this.Properties.CAN_REPEAT, value]);
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
                this.changes.push([this.Properties.PLAYBACKSTATUS, value]);
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
                this.changes.push([this.Properties.REPEAT, value]);
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
                this.changes.push([this.Properties.VOLUME, value]);
                this._volume = value;
            }
        }

        get volume() {
            return this._volume;
        }

        set shuffle(value) {
            if(value != this._shuffle) {
                this.changes.push([this.Properties.SHUFFLE, value]);
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
                this.changes.push([this.Properties.LIKE, value]);
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

                    WebMusicApi.seeked(value);
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
            WebMusicApi.warning("Function actionPlay is not available");
        }

        actionPause() {
            WebMusicApi.warning("Function actionPause is not available");
        }

        actionStop() {
            WebMusicApi.warning("Function actionStop is not available");
        }

        actionNext() {
            WebMusicApi.warning("Function actionNext is not available");
        }

        actionPrevious(){
            WebMusicApi.warning("Function actionPrevious is not available");
        }

        actionRepeat(repeatstatus){
            WebMusicApi.warning("Function actionRepeat is not available");
        }

        actionVolume(volume){
            WebMusicApi.warning("Function actionVolume is not available");
        }

        actionToggleShuffle(){
            WebMusicApi.warning("Function actionToggleShuffle is not available");
        }

        actionToggleLike() {
            WebMusicApi.warning("Function actionToggleLike is not available");
        }

        actionTrackPosition(position) {
            WebMusicApi.warning("Function actionTrackPosition is not available");
        }

        actionSearch(searchstring){
            WebMusicApi.warning("Function actionSearch is not available");
        }

        actionShow(type, id){
            WebMusicApi.warning("Function actionShow is not available");
        }

        sendPropertyChange() {

            if(this._metadataChanged) {
                //Always send complete metadata
                this.changes.push([this.Properties.URL, this.url]);
                this.changes.push([this.Properties.ARTIST, this.artist]);
                this.changes.push([this.Properties.TRACK, this.track]);
                this.changes.push([this.Properties.ALBUM, this.album]);
                this.changes.push([this.Properties.ART_URL, this.artUrl]);
                this.changes.push([this.Properties.TRACK_LENGTH, this.trackLength]);

                this._metadataChanged = false;
            }

            super.sendPropertyChange(this.PropertyChangeType.PLAYER);
        }
    };




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

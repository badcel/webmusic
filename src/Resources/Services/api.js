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

    function Player() {}
    Player.prototype = {

        _ready      : false,
        _canControl : false,
        _canPlay    : false,
        _canPause   : false,
        _canSeek    : false,

        _url    : '',
        _artist : '',
        _track  : '',
        _album  : '',
        _artUrl : '',

        _playbackStatus : 0,

        _canGoNext      : false,
        _canGoPrevious  : false,
        _canShuffle     : false,
        _canRepeat      : false,

        _like    : false,
        _shuffle : false,

        _repeat : 0,
        _volume : 50,

        _trackLength   : 0,
        _trackPosition : 0,

        set ready(value) {
            if(value != this._ready) {
                this.changes.push([this.Properties.READY, value]);
                this._ready = value;
            }
        },

        get ready() {
            return this._ready;
        },

        set canControl(value) {
            if(value != this._canControl) {
                this.changes.push([this.Properties.CAN_CONTROL, value]);
                this._canControl = value;
            }
        },

        get canControl() {
            return this._canControl;
        },

        set canPlay(value) {
            if(value != this._canPlay) {
                this.changes.push([this.Properties.CAN_PLAY, value]);
                this._canPlay = value;
            }
        },

        get canPlay() {
            return this._canPlay;
        },

        set canPause(value) {
            if(value != this._canPause) {
                this.changes.push([this.Properties.CAN_PAUSE, value]);
                this._canPause = value;
            }
        },

        get canPause() {
            return this._canPause;
        },

        set canSeek(value) {
            if(value != this._canSeek) {
                this.changes.push([this.Properties.CAN_SEEK, value]);
                this._canSeek = value;
            }
        },

        get canSeek() {
            return this._canSeek;
        },

        set url(value) {
            if(value != this._url) {
                this.changes.push([this.Properties.URL, value]);
                this._url = value;
            }
        },

        get url() {
            return this._url;
        },

        set artist(value) {
            if(value != this._artist) {
                this.changes.push([this.Properties.ARTIST, value]);
                this._artist = value;
            }
        },

        get artist() {
            return this._artist;
        },

        set track(value) {
            if(value != this._track) {
                this.changes.push([this.Properties.TRACK, value]);
                this._track = value;
            }
        },

        get track() {
            return this._track;
        },

        set album(value) {
            if(value != this._album) {
                this.changes.push([this.Properties.ALBUM, value]);
                this._album = value;
            }
        },

        get album() {
            return this._album;
        },

        set artUrl(value) {
            if(value != this._artUrl) {
                this.changes.push([this.Properties.ART_URL, value]);
                this._artUrl = value;
            }
        },

        get artUrl() {
            return this._artUrl;
        },

        set playbackStatus(value) {
            if(value != this._playbackStatus) {
                this.changes.push([this.Properties.PLAYBACKSTATUS, value]);
                this._playbackStatus = value;
            }
        },

        get playbackStatus() {
            return this._playbackStatus;
        },

        set canGoNext(value) {
            if(value != this._canGoNext) {
                this.changes.push([this.Properties.CAN_GO_NEXT, value]);
                this._canGoNext = value;
            }
        },

        get canGoNext() {
            return this._canGoNext;
        },

        set canGoPrevious(value) {
            if(value != this._canGoPrevious) {
                this.changes.push([this.Properties.CAN_GO_PREVIOUS, value]);
                this._canGoPrevious = value;
            }
        },

        get canGoPrevious() {
            return this._canGoPrevious;
        },

        set canShuffle(value) {
            if(value != this._canShuffle) {
                this.changes.push([this.Properties.CAN_SHUFFLE, value]);
                this._canShuffle = value;
            }
        },

        get canShuffle() {
            return this._canShuffle;
        },

        set canRepeat(value) {
            if(value != this._canRepeat) {
                this.changes.push([this.Properties.CAN_REPEAT, value]);
                this._canRepeat = value;
            }
        },

        get canRepeat() {
            return this._canRepeat;
        },

        set repeat(value) {
            if(value != this._repeat) {
                this.changes.push([this.Properties.REPEAT, value]);
                this._repeat = value;
            }
        },

        get repeat() {
            return this._repeat;
        },

        set volume(value) {
            if(value != this._volume) {
                this.changes.push([this.Properties.VOLUME, value]);
                this._volume = value;
            }
        },

        get volume() {
            return this._volume;
        },

        set shuffle(value) {
            if(value != this._shuffle) {
                this.changes.push([this.Properties.SHUFFLE, value]);
                this._shuffle = value;
            }
        },

        get shuffle() {
            return this._shuffle;
        },

        set like(value) {
            if(value != this._like) {
                this.changes.push([this.Properties.LIKE, value]);
                this._like = value;
            }
        },

        get like() {
            return this._like;
        },

        set trackLength(value) {
            if(value != this._trackLength) {
                this.changes.push([this.Properties.TRACK_LENGTH, value]);
                this._trackLength = value;
            }
        },

        get trackLength() {
            return this._trackLength;
        },

        set trackPosition(value) {
            if(value != this._trackPosition) {

                if(this._trackPosition + 2000000 < value
                    || this._trackPosition - 2000000 > value) {

                    WebMusicApi.seeked(value);
                }

                //According to MPRIS2 spec property changes are not tracked
                this._trackPosition = value;
            }
        },

        get trackPosition() {
            return this._trackPosition;
        },


        changes : [],

        sendPropertyChange : function() {
            if(this.changes.length > 0) {

                let info = "";
                for(let i = 0; i < this.changes.length; i++) {
                    info += "<" + this.changes[i][0] + ":" + this.changes[i][1] + ">";
                }
                WebMusicApi.debug(info);

                WebMusicApi.sendPropertyChange(WebMusicApi.PropertyChangeType.PLAYER, this.changes);
                this.changes = [];
            }
        }
    };

    Player.prototype.Action = {
        STOP    : 'stop',
        PLAY    : 'play',
        PAUSE   : 'pause',
        NEXT    : 'next',
        PREVIOUS: 'previous',
        REPEAT  : 'repeat',
        VOLUME  : 'volume',
        TRACK_POSITION : 'track-position',
        TOGGLE_SHUFFLE : 'toggle-shuffle',
        TOGGLE_LIKE    : 'toggle-like'
    };

    Player.prototype.PlaybackState = {
        STOP : 0,
        PLAY : 1,
        PAUSE: 2
    };

    Player.prototype.Properties = {
        READY           : 'ready',
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

    WebMusicApi.Player = new Player();

    function Browser() {}
    Browser.prototype.Action = {
        SEARCH    : 'search',
        SHOW      : 'show'
    };

    Browser.prototype.ActionShowType = {
        TRACK    : 'track',
        ALBUM    : 'album',
        ARTIST   : 'artist',
        SHOW     : 'show'
    };

    WebMusicApi.Browser = new Browser();

    WebMusicApi.PropertyChangeType = {
        PLAYER   : 0,
        PLAYLIST : 1,
        TRACKLIST: 2,
    };

})(this);

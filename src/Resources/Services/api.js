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

    WebMusicApi.PlayerAction = {
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

    WebMusicApi.BrowserAction = {
        SEARCH    : 'search',
        SHOW      : 'show'
    };

    WebMusicApi.ActionShowType = {
        TRACK    : 'track',
        ALBUM    : 'album',
        ARTIST   : 'artist',
        SHOW     : 'show'
    };

    WebMusicApi.PlaybackState = {
        STOP : 0,
        PLAY : 1,
        PAUSE: 2,
    };

    WebMusicApi.ClearChanges = function() {
        WebMusicApi.Player.changes = [];
    };

    WebMusicApi.SendChanges = function() {
        //Todo

        WebMusicApi.ClearChanges();
    };

    function Player() {}
    Player.prototype = {

        ready      : false,
        canControl : false,
        canPlay    : false,
        canPause   : false,
        canSeek    : false,

        url    : '',
        artist : '',
        track  : '',
        album  : '',
        artUrl : '',

        playbackStatus : 0,

        canGoNext      : false,
        canGoPrevious  : false,
        canShuffle     : false,
        canRepeat      : false,

        like    : false,
        shuffle : false,

        repeat : 0,
        volume : 50,

        trackLength   : 0,
        trackPosition : 0,

        changes : []
    };

    WebMusicApi.Player = new Player();

    Object.defineProperty(WebMusicApi, 'ready', {
        set: function (value) {
            if(value != WebMusicApi.Player.ready) {
                WebMusicApi.Player.changes.push({Property: 'ready', Value: value});
                WebMusicApi.Player.ready = value;
            }
        },
        get: function() { return WebMusicApi.Player.ready; }
    });

    Object.defineProperty(WebMusicApi, 'canControl', {
        set: function (value) {
            if(value != WebMusicApi.Player.canControl) {
                WebMusicApi.Player.changes.push({Property: 'canControl', Value: value});
                WebMusicApi.Player.canControl = value;
            }
        },
        get: function() { return WebMusicApi.Player.canControl; }
    });

    Object.defineProperty(WebMusicApi, 'canPlay', {
        set: function (value) {
            if(value != WebMusicApi.Player.canPlay) {
                WebMusicApi.Player.changes.push({Property: 'canPlay', Value: value});
                WebMusicApi.Player.canPlay = value;
            }
        },
        get: function() { return WebMusicApi.Player.canPlay; }
    });

    Object.defineProperty(WebMusicApi, 'canPause', {
        set: function (value) {
            if(value != WebMusicApi.Player.canPause) {
                WebMusicApi.Player.changes.push({Property: 'canPause', Value: value});
                WebMusicApi.Player.canPause = value;
            }
        },
        get: function() { return WebMusicApi.Player.canPause; }
    });

    Object.defineProperty(WebMusicApi, 'canSeek', {
        set: function (value) {
            if(value != WebMusicApi.Player.canSeek) {
                WebMusicApi.Player.changes.push({Property: 'canSeek', Value: value});
                WebMusicApi.Player.canSeek = value;
            }
        },
        get: function() { return WebMusicApi.Player.canSeek; }
    });

    Object.defineProperty(WebMusicApi, 'url', {
        set: function (value) {
            if(value != WebMusicApi.Player.url) {
                WebMusicApi.Player.changes.push({Property: 'url', Value: value});
                WebMusicApi.Player.url = value;
            }
        },
        get: function() { return WebMusicApi.Player.url; }
    });

    Object.defineProperty(WebMusicApi, 'artist', {
        set: function (value) {
            if(value != WebMusicApi.Player.artist) {
                WebMusicApi.Player.changes.push({Property: 'artist', Value: value});
                WebMusicApi.Player.artist = value;
            }
        },
        get: function() { return WebMusicApi.Player.artist; }
    });

    Object.defineProperty(WebMusicApi, 'track', {
        set: function (value) {
            if(value != WebMusicApi.Player.track) {
                WebMusicApi.Player.changes.push({Property: 'track', Value: value});
                WebMusicApi.Player.track = value;
            }
        },
        get: function() { return WebMusicApi.Player.track; }
    });

    Object.defineProperty(WebMusicApi, 'album', {
        set: function (value) {
            if(value != WebMusicApi.Player.album) {
                WebMusicApi.Player.changes.push({Property: 'album', Value: value});
                WebMusicApi.Player.album = value;
            }
        },
        get: function() { return WebMusicApi.Player.album; }
    });

    Object.defineProperty(WebMusicApi, 'artUrl', {
        set: function (value) {
            if(value != WebMusicApi.Player.artUrl) {
                WebMusicApi.Player.changes.push({Property: 'artUrl', Value: value});
                WebMusicApi.Player.artUrl = value;
            }
        },
        get: function() { return WebMusicApi.Player.artUrl; }
    });

    Object.defineProperty(WebMusicApi, 'playbackStatus', {
        set: function (value) {
            if(value != WebMusicApi.Player.playbackStatus) {
                WebMusicApi.Player.changes.push({Property: 'playbackStatus', Value: value});
                WebMusicApi.Player.playbackStatus = value;
            }
        },
        get: function() { return WebMusicApi.Player.playbackStatus; }
    });

    Object.defineProperty(WebMusicApi, 'canGoNext', {
        set: function (value) {
            if(value != WebMusicApi.Player.canGoNext) {
                WebMusicApi.Player.changes.push({Property: 'canGoNext', Value: value});
                WebMusicApi.Player.canGoNext = value;
            }
        },
        get: function() { return WebMusicApi.Player.canGoNext; }
    });

    Object.defineProperty(WebMusicApi, 'canGoPrevious', {
        set: function (value) {
            if(value != WebMusicApi.Player.canGoPrevious) {
                WebMusicApi.Player.changes.push({Property: 'canGoPrevious', Value: value});
                WebMusicApi.Player.canGoPrevious = value;
            }
        },
        get: function() { return WebMusicApi.Player.canGoPrevious; }
    });

    Object.defineProperty(WebMusicApi, 'canShuffle', {
        set: function (value) {
            if(value != WebMusicApi.Player.canShuffle) {
                WebMusicApi.Player.changes.push({Property: 'canShuffle', Value: value});
                WebMusicApi.Player.canShuffle = value;
            }
        },
        get: function() { return WebMusicApi.Player.canShuffle; }
    });

    Object.defineProperty(WebMusicApi, 'canRepeat', {
        set: function (value) {
            if(value != WebMusicApi.Player.canRepeat) {
                WebMusicApi.Player.changes.push({Property: 'canRepeat', Value: value});
                WebMusicApi.Player.canRepeat = value;
            }
        },
        get: function() { return WebMusicApi.Player.canRepeat; }
    });

    Object.defineProperty(WebMusicApi, 'repeat', {
        set: function (value) {
            if(value != WebMusicApi.Player.repeat) {
                WebMusicApi.Player.changes.push({Property: 'repeat', Value: value});
                WebMusicApi.Player.repeat = value;
            }
        },
        get: function() { return WebMusicApi.Player.repeat; }
    });

    Object.defineProperty(WebMusicApi, 'volume', {
        set: function (value) {
            if(value != WebMusicApi.Player.volume) {
                WebMusicApi.Player.changes.push({Property: 'volume', Value: value});
                WebMusicApi.Player.volume = value;
            }
        },
        get: function() { return WebMusicApi.Player.volume; }
    });

    Object.defineProperty(WebMusicApi, 'shuffle', {
        set: function (value) {
            if(value != WebMusicApi.Player.shuffle) {
                WebMusicApi.Player.changes.push({Property: 'shuffle', Value: value});
                WebMusicApi.Player.shuffle = value;
            }
        },
        get: function() { return WebMusicApi.Player.shuffle; }
    });

    Object.defineProperty(WebMusicApi, 'like', {
        set: function (value) {
            if(value != WebMusicApi.Player.like) {
                WebMusicApi.Player.changes.push({Property: 'like', Value: value});
                WebMusicApi.Player.like = value;
            }
        },
        get: function() { return WebMusicApi.Player.like; }
    });

    Object.defineProperty(WebMusicApi, 'trackLength', {
        set: function (value) {
            if(value != WebMusicApi.Player.trackLength) {
                WebMusicApi.Player.changes.push({Property: 'trackLength', Value: value});
                WebMusicApi.Player.trackLength = value;
            }
        },
        get: function() { return WebMusicApi.Player.trackLength; }
    });

    Object.defineProperty(WebMusicApi, 'trackPosition', {
        set: function (value) {
            if(value != WebMusicApi.Player.trackPosition) {
                WebMusicApi.Player.changes.push({Property: 'trackPosition', Value: value});
                WebMusicApi.Player.trackPosition = value;
            }
        },
        get: function() { return WebMusicApi.Player.trackPosition; }
    });

})(this);

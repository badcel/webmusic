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

    class ExamplePlayer extends WebMusic.Api.BasePlayer {
        constructor() {
            super();

            this.canControl = true;
            this.canPlay    = true;
            this.canPause   = false;
            this.canSeek    = false;

            this.canGoNext     = false;
            this.canGoPrevious = false;
            this.canShuffle    = false;
            this.canRepeat     = false;

            setTimeout(this.update.bind(this), 2500);
        }

        update() {
            //Test connection to webmusic
            //this.ping();

            this.metadata.url     = 'http://webmusic.tiede.org/id/1';
            this.metadata.artists =  ['Artist 1', 'Artist 2'];
            this.metadata.track   = 'Test Track';
            this.metadata.album   = 'Test Album';

            this.playbackStatus = this.PlaybackState.PLAY;

            this.sendPropertyChange();

            //setTimeout(this.update.bind(this), 5000);
        }
    }

    class ExamplePlaylist extends WebMusic.Api.BasePlaylist {
        constructor() {
            super();

            setTimeout(this.update.bind(this), 3500);
        }

        update() {
            this.count = 2;

            //Default: this.orderings = [this.ordering.USER]
            //this.orderings = [this.ordering.USER, this.ordering.ALPHABETICAL];

            let p = new WebMusic.Api.Playlist('/org/webmusic/playlist/1', 'Testplaylist', '');
            this.activePlaylist = p;

            this.sendPropertyChange();

            //Only send this for playlists which changed and are not active.
            //If the active playlists changes a property change is emited automatically.
            this.sendPlaylistChanged(p);
        }

        actionGetPlaylists(index, maxcount, order, reverseorder) {
            let p = new WebMusic.Api.Playlist('/org/webmusic/playlist/1', 'Testplaylist', '');

            let p2 = new WebMusic.Api.Playlist('/org/webmusic/playlist/2', 'Testplaylist2', '');
            return [p, p2];
        }
    }

    WebMusicApi.init = function() {
        let player = new ExamplePlayer();
        let playlist = new ExamplePlaylist();

        WebMusic.Api.register(player);
        WebMusic.Api.register(playlist);
    };

})(this); //WebMusicApi scope

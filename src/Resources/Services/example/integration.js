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
            setTimeout(this.update.bind(this), 2500);
        }

        update() {
            this.ping();
        }

    }

    WebMusicApi.init = function() {
        let player = new ExamplePlayer();
        WebMusic.Api.register(player);
    };

})(this); //WebMusicApi scope

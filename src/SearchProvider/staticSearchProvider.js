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

const Gio  = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Lang = imports.lang;

const StaticSearchProvider = new Lang.Class({
    Name: 'StaticSearchProvider',

    _currentId       : 0,
    _terms           : [],

    _init: function() {

    },

    GetInitialResultSetAsync: function(terms, callback) {
        this._currentId = 1;
        this._terms = [];

        this._handleSearch(terms, callback);
    },

    GetSubsearchResultSetAsync: function(terms, callback){
        this._handleSearch(terms, callback);
    },

    GetResultMetasAsync: function(ids, callback) {
        let metas = [];
        metas.push({ name: new GLib.Variant('s', _("WebMusic")),
                     id: new GLib.Variant('s', this._currentId.toString()),
                     description: new GLib.Variant('s', _("Search for %s").format(this._terms.join(' '))),
                     icon: (new Gio.ThemedIcon({ name: 'audio-x-generic' })).serialize()
        });

        callback(metas);
    },

    _handleSearch: function(terms, callback) {
        let ret = (++this._currentId).toString();
        this._terms = terms;
        callback([ret]);
    }
});


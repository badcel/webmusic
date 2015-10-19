/*
 *   Copyright (c) 2013 Giovanni Campagna <scampa.giovanni@gmail.com>
 *   Copyright (C) 2015  Marcel Tiede
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

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Lang = imports.lang;

const SearchProviderInterface = Gio.resources_lookup_data('/org/gnome/shell/ShellSearchProvider2.xml', 0).toArray().toString();

const SearchProvider = new Lang.Class({
    Name: 'WebMusicSearchProvider',

    _init: function(application) {
        this._app = application;

        this._impl = Gio.DBusExportedObject.wrapJSObject(SearchProviderInterface, this);
    },

    export: function(connection, path) {
        return this._impl.export(connection, path);
    },

    unexport: function(connection) {
        return this._impl.unexport_from_connection(connection);
    },

    GetInitialResultSetAsync: function(params, invocation) {
        let ret = [];

        return ret;
    },

    GetSubsearchResultSet: function(previous, terms) {
        let ret = [];

        return ret;
    },

    GetResultMetas: function(identifiers) {
        let ret = [];

        return ret;
    },

    ActivateResult: function(id, terms, timestamp) {
    },

    LaunchSearch: function(terms, timestamp) {
    },
});


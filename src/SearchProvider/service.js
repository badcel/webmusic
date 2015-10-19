/*
 *   Copyright (c) 2012 Giovanni Campagna <scampa.giovanni@gmail.com>
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

pkg.initGettext();
pkg.initFormat();
pkg.require({ 'Gio': '2.0',
              'GLib': '2.0',
              'GObject': '2.0'});

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Lang = imports.lang;

const SearchProvider = imports.searchProvider;

function initEnvironment() {
    window.getApp = function() {
        return Gio.Application.get_default();
    };
}

const Service = new Lang.Class({
    Name: 'WebMusicService',
    Extends: Gio.Application,

    _init: function() {
        this.parent({ application_id: pkg.name,
                      flags: Gio.ApplicationFlags.IS_SERVICE,
                      inactivity_timeout: 60000 });
        GLib.set_application_name(_("WebMusic"));

        this._searchProvider = new SearchProvider.SearchProvider(this);
    },

    _onQuit: function() {
        this.quit();
    },

    vfunc_dbus_register: function(connection, path) {
        this.parent(connection, path);

        this._searchProvider.export(connection, path);
        return true;
    },

/*
  Can't do until GApplication is fixed.

    vfunc_dbus_unregister: function(connection, path) {
        this._searchProvider.unexport(connection);

        this.parent(connection, path);
    },
*/

    vfunc_startup: function() {
        this.parent();
    },

    vfunc_activate: function() {
        // do nothing, this is a background service
    },

    vfunc_shutdown: function() {
        this.parent();
    }
});

function main(argv) {
    initEnvironment();

    return (new Service()).run(argv);
}


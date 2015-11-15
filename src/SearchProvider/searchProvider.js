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
const WebMusic = imports.gi.libwebmusic;

const SearchProviderInterface = Gio.resources_lookup_data('/org/gnome/shell/ShellSearchProvider2.xml', 0).toArray().toString();

const SearchProvider = new Lang.Class({
    Name: 'WebMusicSearchProvider',

    _currentId : 0,
    _terms : [],
    _enable : false,

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

    _checkService: function() {
        let settings = new Gio.Settings({schema_id: "org.WebMusic.Browser"});
        let lastService = settings.get_string("last-used-service");

        if (lastService.length > 0) {
            let service = new WebMusic.Service();
            service.Load(lastService);
            this._enable = service.get_HasSearchUrl();
            if (this._enable) {
                log("Search for webmusic service " + lastService + " enabled.");
            }
        }
    },

    _getTerm: function() {
        let ret = '';
        for (let i = 0; i < this._terms.length; i++) {
            ret += this._terms[i] + ' ';
        }

        return ret;
    },

    GetInitialResultSetAsync: function(terms, invocation) {
        this._app.hold();
        this._currentId = 1;
        this._terms = [];

        let ret = '';

        this._checkService();

        if (this._enable) {
            ret = (++this._currentId).toString();
            this._terms = terms;
        }

        this._app.release();
        invocation.return_value(new GLib.Variant('(as)', [[ret]]));
    },

    GetSubsearchResultSet: function(previous, terms) {
        this._app.hold();
        let ret = '';

        if (this._enable) {
            ret = (++this._currentId).toString();
            this._terms = terms;
        }

        this._app.release();
        return [ret];
    },

    GetResultMetas: function(identifiers) {
        this._app.hold();
        let ret = [];

        if(this._enable) {
            ret.push({ name: new GLib.Variant('s', _("WebMusic")),
                id: new GLib.Variant('s', this._currentId.toString()),
                description: new GLib.Variant('s', _("Search for %s").format(this._getTerm())),
                icon: (new Gio.ThemedIcon({ name: 'audio-x-generic' })).serialize()});
        }

        this._app.release();
        return ret;
    },

    ActivateResult: function(id, terms, timestamp) {
        this._app.hold();

        let vd = this._getSearchVariantDict(terms);
        this._activateAction('load', vd, timestamp);
    },

    LaunchSearch: function(terms, timestamp) {
        this._app.hold();

        let vd = this._getSearchVariantDict(terms);
        this._activateAction('load', vd, timestamp);
    },

    _getSearchVariantDict : function(terms) {
        let dictionary = new GLib.Variant('a{sv}',
            { 'search': new GLib.Variant('s', terms.join(' '))}
        );

        return dictionary;
    },

    _activateAction: function(action, parameter, timestamp) {
        let wrappedParam;

        if (parameter) {
            wrappedParam = [parameter];
        } else {
            wrappedParam = [];
        }

        Gio.DBus.session.call('org.WebMusic',
                              '/org/WebMusic',
                              'org.freedesktop.Application',
                              'ActivateAction',
                              new GLib.Variant('(sava{sv})', [action, wrappedParam,
                                                              this._getPlatformData(timestamp)]),
                              null,
                              Gio.DBusCallFlags.NONE,
                              -1, null, Lang.bind(this, function(connection, result) {
                                  try {
                                      connection.call_finish(result);
                                  } catch(e) {
                                      log('Failed to launch application: ' + e);
                                  }

                                  this._app.release();
                              }));
    },

    _getPlatformData: function(timestamp) {
        return {'desktop-startup-id': new GLib.Variant('s', '_TIME' + timestamp) };
    },
});


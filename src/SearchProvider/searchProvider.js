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

imports.searchPath.unshift(WebMusic.Directory.GetPkgDataDir());

const Gio              = imports.gi.Gio;
const GLib             = imports.gi.GLib;
const Lang             = imports.lang;
const WebMusic         = imports.gi.libwebmusic;

const StaticProviders  = imports.staticSearchProvider;
const DynamicProviders = imports.Services;

const SearchProviderInterface = Gio.resources_lookup_data('/org/gnome/shell/ShellSearchProvider2.xml', 0).toArray().toString();

const SearchProvider = new Lang.Class({
    Name: 'SearchProvider',

    _enable          : false,
    _service         : null,
    _provider        : null,
    _cancellable     : null,

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

    _prepareProvider: function() {
        this._enable = false;
        let settings = new Gio.Settings({schema_id: 'org.WebMusic.Browser'});
        let lastService = settings.get_string('last-used-service');

        if (lastService.length > 0) {
            this._service = new WebMusic.Service();
            this._service.Load(lastService);

            let name = this._service.get_Name();

            if(this._service.get_HasSearchProvider()) {
                this._enable = true;
                let ident = this._service.get_Ident();
                let file = this._service.get_SearchProvider().slice(0,-3);
                this._provider = new DynamicProviders[ident][file][name + 'SearchProvider']();

                //log('Using dynamic search provider for %s'.format(name));

            } else if(this._service.get_HasSearchUrl()) {
                this._enable = true;
                this._provider = new StaticProviders.StaticSearchProvider();

                //log('Using generic static search provider for %s'.format(name));

            }

        } else {
            log('Unknown last used service, can\'t prepare search provider.');
        }

        return this._enable;
    },

    _createNewCancelObject: function() {
        if(this._cancellable != null) {
            this._cancellable.cancel();
        }

        this._cancellable = new Gio.Cancellable();
    },

    GetInitialResultSetAsync: function(terms, invocation) {
        this._app.hold();

        if(this._prepareProvider()) {

            this._createNewCancelObject();

            this._provider.GetInitialResultSetAsync(terms, Lang.bind(this,
                function(ids) {
                    this._app.release();
                    this._active = false;
                    invocation.return_value(new GLib.Variant('(as)', [ ids ]));
            }), this._cancellable);
        } else {
            log('Error: No provider available');
            this._app.release();
        }
    },

    GetSubsearchResultSetAsync: function(params, invocation) {
        let [previousResults, terms] = params;
        this._app.hold();

        if(this._enable) {

            this._createNewCancelObject();

            this._provider.GetSubsearchResultSetAsync(terms, Lang.bind(this,
                function(ids) {
                    this._app.release();
                    invocation.return_value(new GLib.Variant('(as)', [ ids ]));
            }), this._cancellable);
        } else {
            log('Error: No provider available');
            this._app.release();
        }

    },

    GetResultMetasAsync: function(params, invocation) {
        let ids = params[0];
        this._app.hold();
        let ret = [];

        this._createNewCancelObject();

        if(this._enable) {
            this._provider.GetResultMetasAsync(ids, Lang.bind(this,
                function(metas) {
                    this._app.release();
                    invocation.return_value(new GLib.Variant('(aa{sv})', [ metas ]));
            }), this._cancellable);
        } else {
            log('Error: No provider available');
            this._app.release();
        }
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
                                      log('Failed to launch application: %s'.format(e));
                                  }

                                  this._app.release();
                              }));
    },

    _getPlatformData: function(timestamp) {
        return {'desktop-startup-id': new GLib.Variant('s', '_TIME' + timestamp) };
    },
});


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

const GdkPixbuf = imports.gi.GdkPixbuf;
const Gio       = imports.gi.Gio;
const GLib      = imports.gi.GLib;
const Soup      = imports.gi.Soup;
const Lang      = imports.lang;

const NUMBER_RESULTS = 3;

const DeezerSearchProvider = new Lang.Class({
    Name: 'DeezerSearchProvider',

    _session       : null,
    _dataCache     : null,
    _iconDataCache : [],

    _init: function(cancellable) {
        this._session = new Soup.Session();
        this._session.max_conns_per_host = NUMBER_RESULTS;
    },

    get _ids() {
        let ids = [];

        for(let i = 0; i < this._dataCache.length; i++) {
            ids.push(this._dataCache[i].id.toString());
        }

        return ids;
    },

    get _iconDataCacheReady() {
        for(let i = 0; i < this._dataCache.length; i++) {
            let id = this._dataCache[i].album.id;
            if(!this._iconDataCache[id] || this._iconDataCache[id] == null) {
                return false;
            }
        }

        return true;
    },

    GetInitialResultSetAsync: function(terms, callback, cancellable) {
        this._handleSearch(terms, callback, cancellable);
    },

    GetSubsearchResultSetAsync: function(terms, callback, cancellable){
        this._handleSearch(terms, callback, cancellable);
    },

    GetResultMetasAsync: function(ids, callback, cancellable) {
        let metas = [];
        for(let i = 0; i < ids.length; i++) {

            let idSearch = ids[i];
            let idFound = this._dataCache[i].id;
            if(idFound != idSearch) {
                log("Requested id %s not found in the data cache".format(idSearch));
                continue;
            }

            let title   = this._dataCache[i].title;
            let artist  = this._dataCache[i].artist.name;
            let album   = this._dataCache[i].album.title;
            let albumId = this._dataCache[i].album.id;

            let meta = { id: new GLib.Variant('s', idFound.toString()),
                         name: new GLib.Variant('s', title),
                         description: new GLib.Variant('s', _("by %s").format(artist) + ' ' + _("from %s").format(album))
            };

            if(!this._iconDataCache[albumId]) {
                log('Fallback to default icon, because icon-data is missing');
                let gIcon = new Gio.ThemedIcon({ name: 'audio-x-generic' });
                meta['icon'] = gIcon.serialize();
            } else {
                meta['icon-data'] = this._iconDataCache[albumId];
            }
            metas.push(meta);
        }

        callback(metas);
    },

    _loadIcon: function(callback, albumId, url, cancellable) {
        let soupUri = new Soup.URI(url);
        let message = new Soup.Message({method: "GET", uri: soupUri});
        try {
            this._session.send_async(message, cancellable, Lang.bind(this,
                function(message, async_res) {
                    try {
                        let stream = message.send_finish(async_res);

                        GdkPixbuf.Pixbuf.new_from_stream_async(stream, cancellable, Lang.bind(this,
                            function(obj, async_res){
                                let pixbuf = GdkPixbuf.Pixbuf.new_from_stream_finish(async_res);

                                let iconData = [
                                    pixbuf.get_width(),
                                    pixbuf.get_height(),
                                    pixbuf.get_rowstride(),
                                    pixbuf.get_has_alpha(),
                                    pixbuf.get_bits_per_sample(),
                                    pixbuf.get_n_channels(),
                                    pixbuf.read_pixel_bytes()];

                                this._iconDataCache[albumId] = new GLib.Variant('(iiibiiay)', iconData);

                                if(this._iconDataCacheReady) {
                                    callback(this._ids);
                                }
                        }));
                    } catch(e) {
                        if (e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
                           return;
                        }

                        throw e;
                    }

                }));
        } catch(e) {
            if (e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
               return;
            }

            throw e;
        }

    },

    _loadIcons: function(callback, cancellable) {
        let soupUri, message;
        let missingAlbums = false;

        let albums = [];

        for(let i = 0; i < this._dataCache.length; i++) {
            let albumId  = this._dataCache[i].album.id;
            let url = this._dataCache[i].album.cover_medium;

            if(!this._iconDataCache[albumId] || this._iconDataCache[albumId] == null) {
                missingAlbums = true;

                if(albums.indexOf(albumId) == -1) {
                    albums.push(albumId);
                    this._loadIcon(callback, albumId, url, cancellable);
                } else {
                    //Album is already queued for loading, ignore
                }

            }
        }

        if(!missingAlbums) {
            callback(this._ids);
        }
    },

    _handleSearch: function(terms, callback, cancellable) {

        let term = terms.join(' ');
        let soupUri = new Soup.URI('http://api.deezer.com/search?q=%s'.format(term));
        let message = new Soup.Message({method: "GET", uri: soupUri});

        try {
            this._session.send_async(message, cancellable, Lang.bind(this,
                function(message, async_res) {

                    try {
                        let stream = message.send_finish(async_res);

                        let dataInputStream = new Gio.DataInputStream({base_stream: stream});

                        dataInputStream.read_line_async(0, cancellable, Lang.bind(this,
                            function(dataInputStream, async_res, user_data){

                                let [lineout, charlength, error] = dataInputStream.read_line_finish(async_res)
                                let response = JSON.parse(lineout);

                                this._dataCache = [];
                                let count = response.data.length > NUMBER_RESULTS? NUMBER_RESULTS : response.data.length;

                                for(let i = 0; i < count; i++) {
                                    this._dataCache[i] = response.data[i];
                                }
                                this._loadIcons(callback, cancellable);
                            }));
                        } catch(e) {

                            if (e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
                                return;
                            }

                            throw e;
                        }
                    }));

            } catch(e) {
                if (e.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
                    return;
                }

                throw e;
            }
    }
});

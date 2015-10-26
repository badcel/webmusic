/*
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

using WebMusic.Lib;

[CCode (gir_namespace = "LibSearchProvider", gir_version = "0.1")]
namespace LibSearchProvider {

    private Service GetLastUsedService() {
        //TODO: Make dynamic request to settings
        return new Service("deezer");
    }

    public string GetSearchPath() {
        return Config.PKG_DATA_DIR;
    }

    public bool CurrentServiceHasSearchUrl() {
        return GetLastUsedService().HasSearchUrl;
    }

    public bool CurrentServiceHasSearchProvider() {
        return GetLastUsedService().HasSearchProvider;
    }

    public string CurrentServiceIdent() {
        return GetLastUsedService().Ident;
    }
}

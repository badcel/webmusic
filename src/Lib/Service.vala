/*
 *   Copyright (C) 2014, 2015  Marcel Tiede
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

namespace LibWebMusic {

    public errordomain ServiceError {
        LOADING_ERROR,
        MANDATORY_KEY_MISSING
    }

    public class Service : GLib.Object {

        public signal void ServiceLoaded();

        private string mIdent;
        private string mName;
        private string mVersion;
        private int    mApiVersion;
        private string mUrl;

        private bool   mEnabled                = true;
        private string mSearchUrl              = "";
        private string mTrackUrl               = "";
        private string mAlbumUrl               = "";
        private string mArtistUrl              = "";
        private string mIntegrationFilePath    = "";
        private string mSearchProvider         = "";
        private bool   mSupportsShuffle        = false;
        private bool   mSupportsRepeat         = false;
        private bool   mSupportsLike           = false;
        private bool   mSupportsSearch         = false;
        private bool   mSupportsPlaylists      = false;

        public Service(string name) throws ServiceError {
            this.Load(name);
        }

        public string Ident {
            get { return mIdent; }
        }

        public string Name {
            get { return mName; }
        }

        public string Version {
            get { return mVersion; }
        }

        public int ApiVersion {
            get { return mApiVersion; }
        }

        public bool Enabled {
            get { return mEnabled; }
        }

        public string Url {
            get { return mUrl; }
        }

        public string SearchUrl {
            get { return mSearchUrl; }
        }

        public string TrackUrl {
            get { return mTrackUrl; }
        }

        public string AlbumUrl {
            get { return mAlbumUrl; }
        }

        public string ArtistUrl {
            get { return mArtistUrl; }
        }

        public string IntegrationFilePath {
            get { return mIntegrationFilePath; }
        }

        public string SearchProvider {
            get { return mSearchProvider; }
        }

        public bool HasSearchUrl {
            get { return mSearchUrl.length > 0; }
        }

        public bool HasTrackUrl {
            get { return mTrackUrl.length > 0; }
        }

        public bool HasAlbumUrl {
            get { return mAlbumUrl.length > 0; }
        }

        public bool HasArtistUrl {
            get { return mArtistUrl.length > 0; }
        }

        public bool IntegratesService {
            get { return mIntegrationFilePath.length > 0; }
        }

        public bool HasSearchProvider {
            get { return mSearchProvider.length > 0; }
        }

        public bool SupportsShuffle {
            get { return mSupportsShuffle; }
        }

        public bool SupportsRepeat {
            get { return mSupportsRepeat; }
        }

        public bool SupportsLike {
            get { return mSupportsLike; }
        }

        public bool SupportsSearch {
            get { return mSupportsSearch; }
        }

        public bool SupportsPlaylists {
            get { return mSupportsPlaylists; }
        }

        public string to_string() {
            string ret = "%s (%s)\n" +
                         " - Version: %s\n" +
                         " - URL: %s";
            return ret.printf(Ident, Name, Version, Url);
        }

        public static Service[] GetServices() {
            Service[] arr = null;
            FileInfo info = null;

            try {
                File serviceFolder = File.new_for_path (Directory.GetServiceDir());
                FileEnumerator e = serviceFolder.enumerate_children (
                    FileAttribute.STANDARD_TYPE.to_string() + "::" + FileType.DIRECTORY.to_string(),
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

                int number = 0;
                while (((info = e.next_file()) != null)) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        number++;
                    }
                }

                arr = new Service[number];

                number = 0;
                e = serviceFolder.enumerate_children (
                    FileAttribute.STANDARD_TYPE.to_string() + "::" + FileType.DIRECTORY.to_string(),
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

                while (((info = e.next_file()) != null)) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        try {
                            arr[number++] = new Service(info.get_name());
                        } catch(Error e) {
                            critical("Service %s could not be loaded. (%s)", info.get_name(), e.message);
                            arr = new Service[0];
                            break;
                        }
                    }
                }
            } catch(Error e) {
                arr = new Service[0];
                critical("Could not load service files. (%s)", e.message);
            }

            return arr;

        }

        public void Load(string ident) throws ServiceError {
            //TODO Check if newer version is available in homedirectory

            string path = Directory.GetServiceDir() + ident + "/";
            var keyFile = new KeyFile();

            try {
                keyFile.load_from_file(path + ident + ".ini", KeyFileFlags.NONE);
            } catch(Error e) {
                throw new ServiceError.LOADING_ERROR(e.message);
            }

            try {
                //Mandatory keys

                string name       = keyFile.get_string(ident,  "Name");
                string version    = keyFile.get_string(ident,  "Version");
                int apiVersion    = keyFile.get_integer(ident, "ApiVersion");
                string url        = keyFile.get_string(ident,  "Url");

                //Store data if everything was successfully read
                Reset();
                mIdent      = ident;
                mName       = name;
                mVersion    = version;
                mApiVersion = apiVersion;
                mUrl        = url;
            } catch(KeyFileError e) {
                throw new ServiceError.MANDATORY_KEY_MISSING(e.message);
            }

            try {
                //Optional keys

                if(keyFile.has_key(ident, "SearchUrl")) {
                    mSearchUrl = keyFile.get_string(ident, "SearchUrl");
                }

                if(keyFile.has_key(ident, "TrackUrl")) {
                    mTrackUrl = keyFile.get_string(ident, "TrackUrl");
                }

                if(keyFile.has_key(ident, "AlbumUrl")) {
                    mAlbumUrl = keyFile.get_string(ident, "AlbumUrl");
                }

                if(keyFile.has_key(ident, "ArtistUrl")) {
                    mArtistUrl = keyFile.get_string(ident, "ArtistUrl");
                }

                if(keyFile.has_key(ident, "Integration")) {
                    mIntegrationFilePath = path + keyFile.get_string(ident, "Integration");
                }

                if(keyFile.has_key(ident, "SearchProvider")) {
                    mSearchProvider = keyFile.get_string(ident, "SearchProvider");
                }

                if(keyFile.has_key(ident, "Enabled")) {
                    mEnabled = keyFile.get_boolean(ident, "Enabled");
                }

                if(keyFile.has_key(ident, "SupportsShuffle")) {
                    mSupportsShuffle = keyFile.get_boolean(ident, "SupportsShuffle");
                }

                if(keyFile.has_key(ident, "SupportsRepeat")) {
                    mSupportsRepeat = keyFile.get_boolean(ident, "SupportsRepeat");
                }

                if(keyFile.has_key(ident, "SupportsLike")) {
                    mSupportsLike = keyFile.get_boolean(ident, "SupportsLike");
                }

                if(keyFile.has_key(ident, "SupportsSearch")) {
                    mSupportsSearch = keyFile.get_boolean(ident, "SupportsSearch");
                }

                if(keyFile.has_key(ident, "SupportsPlaylists")) {
                    mSupportsPlaylists = keyFile.get_boolean(ident, "SupportsPlaylists");
                }

            } catch(KeyFileError e) {
                warning("Failed to look up optional key from ini file. " +
                        "Certain features may be disabled. (%s)", e.message);
            }

            this.ServiceLoaded();

        }

        private void Reset() {
            mEnabled                = true;
            mSearchUrl              = "";
            mTrackUrl               = "";
            mAlbumUrl               = "";
            mArtistUrl              = "";
            mIntegrationFilePath    = "";
            mSearchProvider         = "";
            mSupportsShuffle        = false;
            mSupportsRepeat         = false;
            mSupportsLike           = false;
            mSupportsSearch         = false;
            mSupportsPlaylists      = false;
        }
    }

}

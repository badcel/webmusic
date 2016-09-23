/*
 *   Copyright (C) 2014  Marcel Tiede
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

using LibWebMusic;
using WebMusic.Browser.Widgets.Osd;
using WebMusic.Browser.Plugins;
using WebKit;
using GLib;

namespace WebMusic.Browser
{
    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/main.ui")]
    private class Browser : Gtk.Notebook {

        public signal void LoadChanged(WebKit.LoadEvent event);

        private Service mService;
        private WebView mWebView;
        private IPlayer mPlayer;
        private int     mLastPage = 2;

        [GtkChild]
        private Gtk.Box mWebViewBox;

        [GtkChild]
        private Gtk.Button mBtnPlayPause;

        [GtkChild]
        private Gtk.Button mBtnPrev;

        [GtkChild]
        private Gtk.Button mBtnNext;

        [GtkChild]
        private Gtk.Image mImgPlay;

        [GtkChild]
        private CoverStage mCoverStage;

        [GtkChild]
        private Gtk.InfoBar mInfoBar;

        [GtkChild]
        private Gtk.LinkButton mInfoLinkButton;

        public Browser(IPlayer player, Service service) {
            mPlayer = player;
            mService = service;

            this.create_widgets();

            mPlayer.PropertiesChanged.connect(OnPropertiesChanged);
        }

        public Service CurrentService {
            get { return mService; }
        }

        public void ClearWebkitCookies() {
            var context = this.mWebView.get_context();
            context.get_cookie_manager().delete_all_cookies();
        }

        public void ClearWebkitCache() {
            var context = this.mWebView.get_context();
            context.clear_cache();
        }

        public void ShowCoverPage(bool showCoverPage) {
            mInfoBar.visible = !mService.IntegratesService;
            this.page = showCoverPage? 1 : 2;
        }

        public void Load(string? service, string? searchTerm) {

            try {
                bool changeService = false;

                if(service != null && service != mService.Name) {
                    changeService = true;
                    debug("Specified service: %s".printf(service));
                    this.mService.Load(service);
                }

                string uri = mService.Url;
                if(searchTerm != null) {
                    debug("Specified search term: %s".printf(searchTerm));
                    if(!mService.HasSearchUrl && !mService.SupportsSearch) {
                        warning(_("The service %s does not support a search function.")
                                .printf(mService.Name));
                    } else {
                        uri = mService.SearchUrl.printf(searchTerm);
                    }
                }

                if(mWebView.uri == null
                    || changeService
                    || searchTerm != null && !mService.SupportsSearch) {

                    mWebView.load_uri(uri);
                } else if(searchTerm != null) {
                    try {
                        mPlayer.Search(searchTerm);
                    } catch(GLib.IOError e) {
                        warning("Failed executing player action 'search'. (%s, %s)", e.message, searchTerm);
                    }
                }

                if(!mService.IntegratesService) {
                    SetCover("");
                    this.reset_playercontrols();
                }
            } catch(ServiceError e) {
                error("Could not load service. (%s)".printf(e.message));
            }
        }

         public void Show(string? service, string type, string id) {

            if(mWebView.uri != null) {
                try {
                    mPlayer.Show(type, id);
                } catch(GLib.IOError e) {
                    warning("Failed executing player action 'show'. (%s)", e.message);
                }
            } else if(mWebView.uri == null && type == "track" && mService.HasTrackUrl){
                string uri = mService.TrackUrl.printf(id);
                mWebView.load_uri(uri);
            } else if(mWebView.uri == null && type == "album" && mService.HasAlbumUrl){
                string uri = mService.AlbumUrl.printf(id);
                mWebView.load_uri(uri);
            } else if(mWebView.uri == null && type == "artist" && mService.HasArtistUrl){
                string uri = mService.ArtistUrl.printf(id);
                mWebView.load_uri(uri);
            } else {
                warning("The service %s does not provide a url to show data of type '%s'",
                    mService.Name, type);
                mWebView.load_uri(mService.Url);
            }

            if(!mService.IntegratesService) {
                SetCover("");
                this.reset_playercontrols();
            }
        }

        private void reset_playercontrols() {
            mBtnNext.sensitive = false;
            mBtnPrev.sensitive = false;
            mBtnPlayPause.sensitive = false;
            mImgPlay.set_from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);
        }

        private void OnPropertiesChanged(HashTable<PlayerProperties, Variant> dict){

            if(dict.contains(PlayerProperties.ART_FILE_LOCAL)) {
                this.SetCover(dict.get(PlayerProperties.ART_FILE_LOCAL).get_string());
            }

            if(dict.contains(PlayerProperties.CAN_GO_NEXT)) {
                var can_go_next = dict.get(PlayerProperties.CAN_GO_NEXT).get_boolean();
                mBtnNext.sensitive = mService.IntegratesService && can_go_next;
            }

            if(dict.contains(PlayerProperties.CAN_GO_PREVIOUS)) {
                var can_go_previous = dict.get(PlayerProperties.CAN_GO_PREVIOUS).get_boolean();
                mBtnPrev.sensitive = mService.IntegratesService && can_go_previous;
            }

            mBtnPlayPause.sensitive = mService.IntegratesService;

            if(dict.contains(PlayerProperties.PLAYBACKSTATUS)) {
                PlayStatus play_status = (PlayStatus) dict.get(PlayerProperties.PLAYBACKSTATUS).get_int64();

                if(play_status == PlayStatus.PLAY) {
                    mImgPlay.set_from_icon_name("media-playback-pause", Gtk.IconSize.BUTTON);
                } else {
                    mImgPlay.set_from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);
                }
            }

            bool has_data = false;

            string track    = "";
            string album    = "";
            string artist   = "";

            if(dict.contains(PlayerProperties.TRACK)) {
                track = dict.get(PlayerProperties.TRACK).get_string();
                has_data = true;
            }

            if(dict.contains(PlayerProperties.ALBUM)) {
                album = dict.get(PlayerProperties.ALBUM).get_string();
                has_data = true;
            }

            if(dict.contains(PlayerProperties.ARTIST)) {
                artist = dict.get(PlayerProperties.ARTIST).get_string();
                has_data = true;
            }

            if(has_data) {
                string by = artist.length > 0? _("by %s").printf(artist) + " " : "";
                string from = album.length > 0? _("from %s").printf(album): "";

                stdout.printf(_("Now playing %s") + " " + by + from +"\n", track, album, artist);
            }
        }

        private void create_widgets () {

            mInfoLinkButton.uri = WebMusic.HOMEPAGE_SERVICES;
            mInfoBar.visible = !mService.IntegratesService;
            mInfoBar.response.connect((id) => {
                mInfoBar.visible = false;
            });

            WebContext c = WebContext.get_default();
            c.set_web_extensions_directory(Config.PKG_LIB_DIR);

            CookieManager cm = c.get_cookie_manager();
            cm.set_persistent_storage(
                Directory.GetCookiesFile(),
                CookiePersistentStorage.TEXT);

            mWebView = new WebView();
            mWebView.load_changed.connect(OnLoadChanged);

            mWebViewBox.pack_start(this.mWebView);

            mCoverStage.Init(mPlayer, mService);
            SetCover(""); //Set default cover to initialize size of object
        }

        private void SetCover(string file_name) {
            string name = file_name.replace("file://", "");

            if(name.length > 0) {
                mCoverStage.LoadImage(name);
            } else {
                mCoverStage.LoadStockIcon("media-optical-cd-audio");
            }
        }

        private void OnLoadChanged(WebKit.LoadEvent event) {
            switch(event) {
                case WebKit.LoadEvent.STARTED:
                    if(this.page != 0) {
                        mLastPage = this.page;
                    }
                    this.page = 0; //Show spinner
                    break;
                case WebKit.LoadEvent.FINISHED:
                    ShowCoverPage(mLastPage == 1? true : false);
                    break;
            }

            this.LoadChanged(event);
        }

        [GtkCallback]
        private void OnBtnPrevClicked(Gtk.Button button) {
            if(mPlayer != null) {
                try {
                    mPlayer.Previous();
                } catch(GLib.IOError e) {
                    warning("Failed executing player action 'previous'. (%s)", e.message);
                }
            }
        }

        [GtkCallback]
        private void OnBtnNextClicked(Gtk.Button button) {
            if(mPlayer != null) {
                try {
                    mPlayer.Next();
                } catch(GLib.IOError e) {
                    warning("Failed executing player action 'next'. (%s)", e.message);
                }
            }
        }

        [GtkCallback]
        private void OnBtnPlayPauseClicked(Gtk.Button button) {
            if(mPlayer != null) {
                try {
                    mPlayer.PlayPause();
                } catch(GLib.IOError e) {
                    warning("Failed executing player action 'pause'. (%s)", e.message);
                }
            }
        }
    }
}

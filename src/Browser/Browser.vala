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
using WebMusic.Browser.Widgets;
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
        private PlayerApi player;
        private int mLastPage = 2;

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
        private ImageOverlay cover_overlay;

        [GtkChild]
        private OsdToolbar osd_toolbar;

        [GtkChild]
        private Gtk.InfoBar mInfoBar;

        [GtkChild]
        private Gtk.LinkButton mInfoLinkButton;

        public Browser(Service service) {
            mService = service;

            player = PlayerApi.get_instance();
            player.PropertiesChanged.connect(on_properties_changed);

            this.create_widgets();
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
                    player.Search(searchTerm);
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
                player.Show(type, id);
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

        private void on_properties_changed(HashTable<string, Variant> dict){

            if(dict.contains(PlayerApi.Property.CAN_GO_NEXT)) {
                var can_go_next = dict.get(PlayerApi.Property.CAN_GO_NEXT).get_boolean();
                mBtnNext.sensitive = mService.IntegratesService && can_go_next;
            }

            if(dict.contains(PlayerApi.Property.CAN_GO_PREVIOUS)) {
                var can_go_previous = dict.get(PlayerApi.Property.CAN_GO_PREVIOUS).get_boolean();
                mBtnPrev.sensitive = mService.IntegratesService && can_go_previous;
            }

            mBtnPlayPause.sensitive = mService.IntegratesService;

            if(dict.contains(PlayerApi.Property.PLAYBACKSTATUS)) {
                PlayStatus play_status = (PlayStatus) dict.get(PlayerApi.Property.PLAYBACKSTATUS).get_int64();

                if(play_status == PlayStatus.PLAY) {
                    mImgPlay.set_from_icon_name("media-playback-pause", Gtk.IconSize.BUTTON);
                } else {
                    mImgPlay.set_from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);
                }
            }


            if(!dict.contains(PlayerApi.Property.METADATA)) {
                return;
            }
            Metadata metadata = PlayerApi.get_instance().Metadata;

            this.SetCover(metadata.ArtFileLocal);

            string track    = metadata.Track;
            string album    = metadata.Album;
            string artists  = string.joinv (", ", metadata.Artists);

            string by = artists.length > 0? _("by %s").printf(artists) + " " : "";
            string from = album.length > 0? _("from %s").printf(album): "";

            stdout.printf(_("Now playing %s") + " " + by + from +"\n", track, album, artists);
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


            cover_overlay.name = "cover_overlay";
            cover_overlay.set_size(300, 300);

            osd_toolbar.init(mService);
            SetCover(""); //Set default cover to initialize cover
        }

        private void SetCover(string file_name) {
            string name = file_name.replace("file://", "");

            if(name.length > 0) {
                cover_overlay.LoadImage(name);
                cover_overlay.remove_style_class("image-overlay-missing-image");
            } else {
                cover_overlay.LoadStockIcon("media-optical-cd-audio");
                cover_overlay.add_style_class("image-overlay-missing-image");
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
            player.Previous();
        }

        [GtkCallback]
        private void OnBtnNextClicked(Gtk.Button button) {
            player.Next();
        }

        [GtkCallback]
        private void OnBtnPlayPauseClicked(Gtk.Button button) {
            player.PlayPause();
        }
    }
}

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

using WebMusic.Lib;
using WebMusic.Browser.Osd;
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
            mCoverStage.Init(mPlayer, mService);

            mPlayer.MetadataChanged.connect(OnMetadataChanged);
            mPlayer.PlayercontrolChanged.connect(OnPlayercontrolChanged);
            mService.ServiceLoaded.connect(OnServiceChanged);

            mWebView.load_uri(mService.Url);
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

        private void OnServiceChanged() {
            mWebView.load_uri(mService.Url);

            if(!mService.IntegratesService) {
                SetCover("");
                OnPlayercontrolChanged(false, false, false, false, false, false,
                                        PlayStatus.STOP, Repeat.NONE);
            }
        }

        private void OnMetadataChanged(string artist, string track, string album, string artUrl) {
            this.SetCover(artUrl);
        }

        private void OnPlayercontrolChanged(bool canGoNext, bool canGoPrev, bool canShuffle,
                            bool canRepeat, bool shuffle, bool like, PlayStatus playStatus, Repeat loopStatus) {

            mBtnNext.sensitive = mService.IntegratesService && canGoNext;
            mBtnPrev.sensitive = mService.IntegratesService && canGoPrev;
            mBtnPlayPause.sensitive = mService.IntegratesService;

            if(playStatus == PlayStatus.PLAY) {
                mImgPlay.set_from_icon_name("media-playback-pause", Gtk.IconSize.BUTTON);
            } else {
                mImgPlay.set_from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);
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
        }

        private void SetCover(string fileName) {
            string f = fileName.replace("file://", "");

            if(f.length > 0) {
                mCoverStage.LoadImage(f);
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

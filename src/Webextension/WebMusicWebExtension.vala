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

using WebKit;
using LibWebMusic;

namespace WebMusic.Webextension {
    private WebMusicControler Controler;

    [DBus(name = "org.WebMusic.Browser")]
    private interface BrowserDBus : GLib.Object {
        public abstract void Quit() throws IOError;
        public abstract void Raise() throws IOError;
        public abstract string GetCurrentService() throws IOError;
    }

    private class WebMusicControler {

        private BrowserDBus mBrowser;
        private JavascriptMusicPlayer mPlayer;
        private Service mService;

        public WebMusicControler() {
            try {
                mBrowser = Bus.get_proxy_sync(BusType.SESSION, "org.WebMusic", "/org/WebMusic");
            } catch(IOError e) {
                error("Could not connect to browser via DBus. (%s)", e.message);
            }

        }

        public void DocumentLoaded(WebPage page) {

            string name = "";
            try {
                name = mBrowser.GetCurrentService();
                debug("Current service %s. (%s)", name, page.get_uri());
            } catch(IOError e) {
                critical("Could not get current service from browser via DBus. " +
                        "Reload page to try again. (%s)", e.message);
                Reset();
                return;
            }

            if(name.length == 0) {
                critical("Can not load service, the service name is empty. " +
                        "Reload page to try again.");
                Reset();
                return;
            }

            Frame f = page.get_main_frame();
            unowned JSCore.GlobalContext context = (JSCore.GlobalContext)f.get_javascript_global_context();

            try {
                if(mPlayer == null) {
                    //First run initialize
                    mService = new Service(name);

                    mPlayer = new JavascriptMusicPlayer(mService);
                    mPlayer.SetContext(context);
                    mPlayer.PropertiesChanged.connect(this.OnPropertiesChanged);
                } else {
                    //Refresh objects
                    mService.Load(name);
                    mPlayer.SetContext(context);
                }
            } catch(ServiceError e) {
                critical("Service file for %s could not be loaded. " +
                        "Reload page to try again. (%s)", name, e.message);

                Reset();
            }
        }

        private void OnPropertiesChanged(HashTable<PlayerProperties,Variant> dict) {

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

        private void Reset() {
            mService = null;
            mPlayer  = null;
        }
    }
}

private void webkit_web_extension_initialize(WebKit.WebExtension extension) {

    Intl.textdomain(Config.GETTEXT_PACKAGE);
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);

    WebMusic.Webextension.Controler = new WebMusic.Webextension.WebMusicControler();

    extension.page_created.connect((extension, page) =>{
        page.document_loaded.connect((page) => {
            WebMusic.Webextension.Controler.DocumentLoaded(page);
        });
    });
}

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
using WebMusic.Webextension.Plugins;

namespace WebMusic.Webextension {
    private WebMusicControler Controler;

    [DBus(name = "org.WebMusic.Browser")]
    private interface BrowserDBus : GLib.Object {
        public abstract void Quit() throws IOError;
        public abstract void Raise() throws IOError;
        public abstract string GetCurrentService() throws IOError;
    }

    private class WebMusicControler {

        private HashTable<string, IPlugin> mPlugins;
        private BrowserDBus mBrowser;
        private JavascriptContext mContext;
        private JavascriptMusicPlayer mPlayer;
        private Settings mSettings;
        private Service mService;

        public WebMusicControler() {
            try {
                mBrowser = Bus.get_proxy_sync(BusType.SESSION, "org.WebMusic", "/org/WebMusic");
            } catch(IOError e) {
                error("Could not connect to browser via DBus. (%s)", e.message);
            }
            mSettings = new Settings("org.WebMusic.Webextension");
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
                    mContext = new JavascriptContext(context);

                    mPlayer = new JavascriptMusicPlayer(mService, mContext);
                    mPlayer.MetadataChanged.connect(this.OnMetadataChanged);

                    this.InitializePlugins();
                } else {
                    //Refresh objects
                    mService.Load(name);
                    mContext.SetContext(context);
                }
            } catch(ServiceError e) {
                critical("Service file for %s could not be loaded. " +
                        "Reload page to try again. (%s)", name, e.message);

                Reset();
            }
        }

        private void InitializePlugins() {

            mPlugins = new HashTable<string, IPlugin>(str_hash, str_equal);
            mPlugins.insert("mpris", new Mpris(mBrowser, mService));
            mPlugins.insert("notifications", new WebMusic.Webextension.Plugins.Notification());

            foreach(IPlugin plugin in mPlugins.get_values()) {
                plugin.RegisterPlayer(mPlayer);
            }

            mSettings.changed.connect(OnSettingsChanged);

            mPlugins["mpris"].Enable = mSettings.get_boolean("enable-mpris");
            mPlugins["notifications"].Enable = mSettings.get_boolean("enable-notifications");

        }

        private void OnSettingsChanged(string key) {
            string index = key.replace("enable-", "");
            mPlugins[index].Enable = mSettings.get_boolean(key);
        }

        private void OnMetadataChanged(string artist, string track, string album, string artUrl) {
            string by = artist.length > 0? _("by %s").printf(artist) + " " : "";
            string from = album.length > 0? _("from %s").printf(album): "";

            stdout.printf(_("Now playing %s") + " " + by + from +"\n", track, album, artist);
        }

        private void Reset() {
            mService = null;
            mContext = null;
            mPlayer  = null;
            mPlugins = null;
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

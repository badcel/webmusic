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
using WebMusic.Browser.Dialogs;
using WebMusic.Browser.Plugins;

namespace WebMusic.Browser
{

    public enum DarkThemeMode {
        ALWAYS,
        ONLY_NORMAL_MODE,
        ONLY_MINI_MODE,
        NEVER;

        public string to_string() {
            string ret = "";

            switch(this) {
                case DarkThemeMode.ALWAYS:
                    ret = "always";
                    break;
                case DarkThemeMode.ONLY_NORMAL_MODE:
                    ret = "only-normal-mode";
                    break;
                case DarkThemeMode.ONLY_MINI_MODE:
                    ret = "only-mini-mode";
                    break;
                case DarkThemeMode.NEVER:
                    ret = "never";
                    break;
            }

            return ret;
        }
    }

    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/application-window.ui")]
    private class AppWindow : Gtk.ApplicationWindow {

        [GtkChild]
        private Gtk.HeaderBar    mHeader;

        [GtkChild]
        private Gtk.MenuButton   mBtnPopover;
        private Browser          mBrowser;
        private Player           player;
        private Settings         mSettings;
        private Settings         mSettingsPlugins;
        private DarkThemeMode    mDarkThemeMode;
        private Service          mService;
        private HashTable<string, IPlugin> mPlugins;

        private bool mMiniMode = false;

        private const ActionEntry[] mActions = {
            { "minimode", WinMiniMode, null, "false"},
            { "show_mini_widget", show_mini_widget, null, "false"},
            { "service",  WinService , "s", "'deezer'"}
        };

        public AppWindow(Gtk.Application app, Service service, Settings settings) {

            Object(application: app);

            this.add_action_entries(mActions, this);

            mSettings = settings;
            mSettings.changed.connect((source, key) => {
                if(key == "use-dark-theme") {
                    ReadDarkThemeMode();
                    RefreshDarkThemeMode();
                }
            });

            mSettingsPlugins = new Settings("org.WebMusic.Browser.Plugins");

            player = Player.get_instance();
            player.PropertiesChanged.connect(on_properties_changed);

            mService = service;
            mService.ServiceLoaded.connect(() =>  {
                if(!mService.IntegratesService) {
                    SetTitle("", "", "");
                }
            });

            this.CreateWidgets(service);
            ReadDarkThemeMode();
            RefreshDarkThemeMode();
            this.initialize_plugins();
        }

        public Browser GetBrowser() {
            return mBrowser;
        }

        public void Load(string? service, string? searchTerm) {
            this.mBrowser.Load(service, searchTerm);
        }

        public void Show(string? service, string type, string id) {
            this.mBrowser.Show(service, type, id);
        }

        private void WinMiniMode(SimpleAction action, Variant? parameter) {
            EnableMiniMode(!action.state.get_boolean());
            action.set_state(new Variant.boolean(mMiniMode));
        }

        private void show_mini_widget(SimpleAction action, Variant? parameter) {
            if(mPlugins.contains("miniwidget")) {
                var b = !action.state.get_boolean();
                mPlugins["miniwidget"].Enable = b;
                action.set_state(new Variant.boolean(b));
            }
        }

        private void WinService(SimpleAction action, Variant? parameter) {
            try {
                mService.Load(parameter.get_string());
                mSettings.set_string("last-used-service", mService.Ident);
                mBrowser.Load(parameter.get_string(), null);
                action.set_state(parameter);
            } catch(ServiceError e) {
                string err = "Service %s could not be loaded. (%s)"
                                .printf(parameter.get_string(), e.message);
                critical(err);
                ErrorDialog.run(err);
            }
        }

        private void initialize_plugins() {

            mPlugins = new HashTable<string, IPlugin>(str_hash, str_equal);
            mPlugins.insert("mpris", new Mpris((WebMusic)this.application, mService));
            mPlugins.insert("notifications", new Notificationn());
            mPlugins.insert("miniwidget", new MiniWidget());

            mSettingsPlugins.changed.connect(on_settings_plugins_changed);

            mPlugins["mpris"].Enable = mSettingsPlugins.get_boolean("enable-mpris");
            mPlugins["notifications"].Enable = mSettingsPlugins.get_boolean("enable-notifications");

        }

        private void on_settings_plugins_changed(string key) {
            string index = key.replace("enable-", "");
            mPlugins[index].Enable = mSettingsPlugins.get_boolean(key);
        }

        private void ReadDarkThemeMode() {
            string mode = mSettings.get_string("use-dark-theme");

            switch(mode) {
                case "always":
                    mDarkThemeMode = DarkThemeMode.ALWAYS;
                    break;
                case "only-normal-mode":
                    mDarkThemeMode = DarkThemeMode.ONLY_NORMAL_MODE;
                    break;
                case "only-mini-mode":
                    mDarkThemeMode = DarkThemeMode.ONLY_MINI_MODE;
                    break;
                case "never":
                    mDarkThemeMode = DarkThemeMode.NEVER;
                    break;
                default:
                    mDarkThemeMode = DarkThemeMode.ONLY_MINI_MODE;
                    break;
            }
        }

        private void RefreshDarkThemeMode() {

            if(mDarkThemeMode == DarkThemeMode.ALWAYS
                    || mDarkThemeMode == DarkThemeMode.ONLY_NORMAL_MODE && !mMiniMode
                    || mDarkThemeMode == DarkThemeMode.ONLY_MINI_MODE && mMiniMode) {
                Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
            } else {
                Gtk.Settings.get_default().gtk_application_prefer_dark_theme = false;
            }

        }

        private void on_properties_changed(HashTable<string, Variant> dict){

            bool has_data = false;

            string artist = "";
            string track  = "";
            string album  = "";

            if(dict.contains(Player.Property.ARTIST)) {
                artist = dict.get(Player.Property.ARTIST).get_string();
                has_data = true;
            }

            if(dict.contains(Player.Property.TRACK)) {
                track = dict.get(Player.Property.TRACK).get_string();
                has_data = true;
            }

            if(dict.contains(Player.Property.ALBUM)) {
                album = dict.get(Player.Property.ALBUM).get_string();
                has_data = true;
            }

            if(has_data) {
                this.SetTitle(artist, track, album);
            }
        }

        private void CreateWidgets(Service service) {

            var b = new Gtk.Builder();
            try {
                b.add_from_resource("/org/WebMusic/Browser/ui/popover-menu.ui");
            } catch(Error e) {
                error("The resource popover-menu.ui could not be loaded. (%s)", e.message);
            }

            mBtnPopover.menu_model = b.get_object("popovermenu") as MenuModel;

            mBrowser = new Browser(service);
            mBrowser.LoadChanged.connect((event) => {
                mBtnPopover.sensitive = (event == WebKit.LoadEvent.FINISHED);
            });
            this.add(mBrowser);
        }

        private void EnableMiniMode(bool miniMode) {
            mMiniMode = miniMode;
            mBrowser.ShowCoverPage(miniMode);

            if(miniMode) {
                this.resize(1,1);
            } else {
                this.resize(1200, 768);
            }

            RefreshDarkThemeMode();
        }

        private void SetTitle(string artist, string track, string album) {
            mHeader.set_title(track.length >0? track : _("WebMusic"));

            string by = artist.length > 0? _("by %s").printf(artist) + " ": "";
            string from = album.length > 0? _("from %s").printf(album) : "";

            if(by.length == 0 && from.length == 0) {
                by = _("Listen to your music");
            }
            mHeader.set_subtitle(by + from);
        }
    }
}

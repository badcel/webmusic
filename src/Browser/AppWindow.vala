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

    private class AppWindow : Gtk.ApplicationWindow {

        private Gtk.HeaderBar    mHeader;
        private Gtk.MenuButton   mBtnPopover;
        private Browser          mBrowser;
        private IPlayer          mPlayer;
        private Settings         mSettings;
        private DarkThemeMode    mDarkThemeMode;
        private Service          mService;

        private bool             mMiniMode = false;

        private const ActionEntry[] mActions = {
            { "minimode", WinMiniMode, null, "false"},
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

            this.set_default_size(1200, 768);

            try {
                mPlayer = Bus.get_proxy_sync(BusType.SESSION, "org.WebMusic.Webextension",
                                        "/org/WebMusic/Webextension");
                mPlayer.MetadataChanged.connect(OnMetadataChanged);
            } catch(IOError e) {
                error("Could not connect to webextension via DBus. (%s)", e.message);
            }

            mService = service;
            mService.ServiceLoaded.connect(() =>  {
                if(!mService.IntegratesService) {
                    SetTitle("", "", "");
                }
            });

            this.CreateWidgets(service);
            ReadDarkThemeMode();
            RefreshDarkThemeMode();
        }

        public Browser GetBrowser() {
            return mBrowser;
        }

        private void WinMiniMode(SimpleAction action, Variant? parameter) {
            EnableMiniMode(!action.state.get_boolean());
            action.set_state(new Variant.boolean(mMiniMode));
        }

        private void WinService(SimpleAction action, Variant? parameter) {
            try {
                mService.Load(parameter.get_string());
                mSettings.set_string("last-used-service", mService.Ident);
                action.set_state(parameter);
            } catch(ServiceError e) {
                string err = "Service %s could not be loaded. (%s)"
                                .printf(parameter.get_string(), e.message);
                critical(err);
                ErrorDialog.run(err);
            }
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

        private void OnMetadataChanged(string artist, string track, string album, string artUrl) {
            this.SetTitle(artist, track, album);
        }

        private void CreateWidgets(Service service) {

            var imgMiniMode = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.MENU);

            var b = new Gtk.Builder();
            b.set_translation_domain(Config.GETTEXT_PACKAGE);
            try {
                b.add_from_resource("/org/WebMusic/Browser/ui/popover-menu.ui");
            } catch(Error e) {
                error("The resource popover-menu.ui could not be loaded. (%s)", e.message);
            }

            var model = b.get_object("popovermenu") as MenuModel;

            mBtnPopover = new Gtk.MenuButton();
            mBtnPopover.image             = imgMiniMode;
            mBtnPopover.always_show_image = true;
            mBtnPopover.sensitive         = false;
            mBtnPopover.menu_model        = model;
            mBtnPopover.use_popover       = true;

            mHeader = new Gtk.HeaderBar();
            mHeader.show_close_button = true;
            mHeader.pack_end(mBtnPopover);
            SetTitle("", "", "");

            this.set_titlebar(mHeader);

            mBrowser = new Browser(mPlayer, service);
            mBrowser.LoadChanged.connect((event) => {
                mBtnPopover.sensitive = (event == WebKit.LoadEvent.FINISHED);
            });
            this.add(mBrowser);

            this.activate_action("service", new Variant.string(mService.Ident));
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

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

namespace WebMusic.Browser {

    [DBus(name = "org.WebMusic.Browser")]
    public class WebMusic : Gtk.Application {

        private AppWindow mAppWindow;
        private Settings  mSettings;

        private const ActionEntry[] mActions = {
            { "show-preferences", AppShowPreferences, null   , null},
            { "show-about"      , AppShowAbout      , null   , null},
            { "quit"            , AppQuit           , null   , null},
            { "load"            , AppLoad           , "a{sv}", null}
        };

        public const string HOMEPAGE = "http://webmusic.tiede.org";
        public const string HOMEPAGE_SERVICES = "http://webmusic.tiede.org/#Services";

        private const GLib.OptionEntry[] mOptions = {
            { "version", 0, 0, OptionArg.NONE, null,
                N_("Show version number"), null },
            { "service", 'S', 0, OptionArg.STRING, null,
                N_("Define the service to use for application startup"), N_("SERVICE") },
            { "search", 's', 0, OptionArg.STRING, null,
                N_("Search service for SEARCH_TERM"), N_("SEARCH_TERM") },
            { "show-track", 't', 0, OptionArg.STRING, null,
                N_("Show given track with id TRACK_ID"), N_("TRACK_ID") },
            { "show-album", 'a', 0, OptionArg.STRING, null,
                N_("Show given album with id ALBUM_ID"), N_("ALBUM_ID") },
            { "show-artist", 'a', 0, OptionArg.STRING, null,
                N_("Show given artist with id ARTIST_ID"), N_("ARTIST_ID") },
            { "list-services", 'l', 0, OptionArg.NONE, null,
                N_("List all supported services"), null },
            { null }
        };

        public WebMusic() {
            Object(application_id: Config.PACKAGE_NAME,
                            flags: ApplicationFlags.FLAGS_NONE);

            this.add_main_option_entries(mOptions);
            this.add_action_entries(mActions, this);

            this.handle_local_options.connect(handle_commandline_options);
        }

        public void Raise() {
            mAppWindow.present_with_time((uint32) TimeVal().tv_sec);
        }

        public void Quit() {
            this.AppQuit(null, null);
        }

        public string GetCurrentService() {
            return mAppWindow.GetBrowser().CurrentService.Ident;
        }

        protected override void startup() {

            base.startup();

            var b = new Gtk.Builder();
            b.set_translation_domain(Config.GETTEXT_PACKAGE);

            try {
                b.add_from_resource("/org/WebMusic/Browser/ui/application-menu.ui");
            } catch(Error e) {
                error("The resource application-menu.ui could not be loaded. (%s)", e.message);
            }

            this.app_menu = b.get_object("app-menu") as MenuModel;

            var coverDir = File.new_for_path(Directory.GetAlbumArtDir());
            if(!coverDir.query_exists()) {
                try {
                    coverDir.make_directory_with_parents();
                } catch(Error e) {
                    error("Could not create directory for album art (%s). (%s)",
                            Directory.GetAlbumArtDir(), e.message);
                }
            }

            mSettings = new Settings("org.WebMusic.Browser");

            if(this.get_is_registered()) {
                try {
                    this.get_dbus_connection().register_object("/org/WebMusic", this);
                } catch(Error e) {
                    error("Could not register application via dbus. (%s)", e.message);
                }
            }
        }

        protected override void activate () {
            this.mAppWindow = create_main_window(null);
            this.mAppWindow.Load(null, null);
        }

        private AppWindow create_main_window(string? strService) {

            if(this.mAppWindow != null) {
                return this.mAppWindow;
            }
            AppWindow appWindow = null;

            try {
                string targetService;
                Service service = null;

                if(strService != null) {
                    debug("Commandline specified service: %s", strService);
                    targetService = strService;
                } else {
                    targetService = mSettings.get_string("last-used-service");

                    if(targetService.length == 0) {
                        targetService = "deezer";
                    }
                }

                service = new Service(targetService);

                mSettings.set_string("last-used-service", targetService);

                appWindow = new AppWindow(this, service, mSettings);
                appWindow.show_all();

                return appWindow;
            } catch(ServiceError e)  {
                string err = _("Startup service %s file could not be loaded. Application shuts down. (%s)")
                                .printf(strService, e.message);
                critical(err);
                ErrorDialog.run(err);
                quit();
            }
            return appWindow;
        }

        private int handle_commandline_options(VariantDict options) {

            if(options.contains("version")) {
                stdout.printf("%s %s\n", Config.PACKAGE, Config.PACKAGE_VERSION);
                return 0;
            }

            if(options.contains("list-services")) {

                Service[] services = Service.GetServices();
                foreach(Service service in services) {
                    if(service.Enabled) {
                        stdout.printf(service.to_string() + "\n");
                    }
                }
                return 0;
            }

            try {
                 if(options.contains("search")
                    || options.contains("service")
                    || options.contains("show-track")
                    || options.contains("show-album")
                    || options.contains("show-artist")) {

                    this.register(null);
                    this.activate_action("load", options.end());
                }
            } catch(Error e) {
                error("Could not register application. (%s)".printf(e.message));
            }
            return -1;
        }

        private void AppShowPreferences(SimpleAction action, Variant? parameter) {
            var preferences = new PreferencesDialog();
            preferences.set_transient_for(mAppWindow);
            preferences.ClearData.connect(OnClearData);
            preferences.present();
        }

        private void OnClearData(DataToClear data) {

            if(DataToClear.CLEAR_COOKIES in data) {
                mAppWindow.GetBrowser().ClearWebkitCookies();
            }

            if(DataToClear.CLEAR_ALBUM_ART in data) {
                var albumArt = File.new_for_path(Directory.GetAlbumArtDir());
                albumArt.enumerate_children_async.begin(
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                Priority.DEFAULT, null, (obj, res) => {
                    try {
                    FileEnumerator enumerator = albumArt.enumerate_children_async.end(res);
                    FileInfo info;
                    File f;
                    while ((info = enumerator.next_file (null)) != null) {

                        if(info.get_file_type () == FileType.REGULAR) {
                            f = enumerator.get_child(info);
                            f.delete();
                        }
                    }
                    } catch (Error e) {
                        string err = "Could not complete deleting the album art. (%s)".printf(e.message);
                        critical(err);
                        ErrorDialog.run(err);
                    }
                });
            }

            if(DataToClear.CLEAR_INTERNET_FILES in data) {
                mAppWindow.GetBrowser().ClearWebkitCache();
            }
        }

        private void AppShowAbout(SimpleAction action, Variant? parameter) {
            AboutDialog.Show(mAppWindow);
        }

        private void AppQuit(SimpleAction? action, Variant? parameter) {
            this.quit();
        }

        private void AppLoad(SimpleAction? action, Variant? parameter) {
            if(parameter != null) {
                string? service = null;

                VariantDict dict = new VariantDict(parameter);

                if(dict.contains("service")) {
                    service = dict.lookup_value("service", VariantType.STRING).get_string();
                }

                this.mAppWindow = this.create_main_window(service);

                if(dict.contains("search")) {
                    string search = dict.lookup_value("search", VariantType.STRING).get_string();
                    this.mAppWindow.Load(service, search);
                } else if(dict.contains("show-track")) {
                    string type = "track";
                    string id = dict.lookup_value("show-track", VariantType.STRING).get_string();
                    this.mAppWindow.Show(service, type, id);
                } else if(dict.contains("show-album")) {
                    string type = "album";
                    string id = dict.lookup_value("show-album", VariantType.STRING).get_string();
                    this.mAppWindow.Show(service, type, id);
                } else if(dict.contains("show-artist")) {
                    string type = "artist";
                    string id = dict.lookup_value("show-artist", VariantType.STRING).get_string();
                    this.mAppWindow.Show(service, type, id);
                }
            }
        }

        public static int main (string[] args) {

            Intl.setlocale(LocaleCategory.ALL, "");
            Intl.textdomain(Config.GETTEXT_PACKAGE);
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);

            Gtk.init(ref args);
            Gtk.IconTheme.get_default().append_search_path(Config.THEME_DIR);
            Gtk.Window.set_default_icon_name(Config.PACKAGE);

            var screen = Gdk.Screen.get_default();
            var provider = new Gtk.CssProvider();
            provider.load_from_resource("/org/WebMusic/Browser/ui/webmusic.css");
            Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            WebMusic app = new WebMusic();
            return app.run(args);
        }
    }
}

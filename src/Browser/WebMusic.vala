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
using WebMusic.Browser.Dialogs;

namespace WebMusic.Browser {

    [DBus(name = "org.WebMusic.Browser")]
    public class WebMusic : Gtk.Application {

        private AppWindow mAppWindow;
        private Browser   mBrowser;
        private Settings  mSettings;
        private static bool mShowVersion   = false;
        //private static bool mQueryService  = false;
        private static bool mListServices  = false;
        private static string? mService    = null;

        private const ActionEntry[] mActions = {
            { "preferences", AppPreferences},
            { "about"      , AppAbout},
            { "quit"       , AppQuit}
        };

        public const string HOMEPAGE = "http://webmusic.tiede.org";
        public const string HOMEPAGE_SERVICES = "http://webmusic.tiede.org/#Services";

        private const GLib.OptionEntry[] mOptions = {
            { "version", 0, 0, OptionArg.NONE, ref mShowVersion,
            N_("Show version number"), null },
            { "service", 'S', 0, OptionArg.STRING, ref mService,
            N_("Define the service to use for application startup"), N_("SERVICE") },
            /*{ "search", 's', 0, OptionArg.STRING, ref mQueryService,
            N_("Search service for SEARCH_TERM"), N_("SEARCH_TERM") },*/
            { "list-services", 'l', 0, OptionArg.NONE, ref mListServices,
            N_("List all supported services"), null },
            { null }
        };

        public WebMusic() {
            Object(application_id: "org.WebMusic",
                            flags: ApplicationFlags.FLAGS_NONE);
        }

        public void Raise() {
            mAppWindow.present_with_time((uint32) TimeVal().tv_sec);
        }

        public void Quit() {
            this.AppQuit(null, null);
        }

        public string GetCurrentService() {
            return mBrowser.CurrentService.Ident;
        }

        protected override void startup() {

            base.startup();

            this.add_action_entries(mActions, this);

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
        }

        protected override void activate () {
            string strService;
            try {
                Service service = null;

                if(mService != null) {
                    strService = mService;
                } else {
                    strService = mSettings.get_string("last-used-service");

                    if(strService.length == 0) {
                        strService = "deezer";
                    }
                }

                service = new Service(strService);

                mSettings.set_string("last-used-service", strService);

                //TODO What if the service is disabled?

                mAppWindow = new AppWindow(this, service, mSettings);
                mAppWindow.show_all();

                mBrowser = mAppWindow.GetBrowser();

                if(this.get_is_registered()) {
                    try {
                        this.get_dbus_connection().register_object("/org/WebMusic", this);
                    } catch(Error e) {
                        error("Could not register application via dbus. (%s)", e.message);
                    }
                }

            } catch(ServiceError e)  {
                string err = _("Startup service %s file could not be loaded. Application shuts down. (%s)")
                                .printf(strService, e.message);
                critical(err);
                ErrorDialog.run(err);
                quit();
            }
        }

        private void AppPreferences(SimpleAction action, Variant? parameter) {
            var preferences = new PreferencesDialog();
            preferences.set_transient_for(mAppWindow);
            preferences.ClearData.connect(OnClearData);
            preferences.present();
        }

        private void OnClearData(DataToClear data) {

            if(DataToClear.CLEAR_COOKIES in data) {
                mBrowser.ClearWebkitCookies();
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
                mBrowser.ClearWebkitCache();
            }
        }

        private void AppAbout(SimpleAction action, Variant? parameter) {
            AboutDialog.Show(mAppWindow);
        }

        private void AppQuit(SimpleAction? action, Variant? parameter) {
            this.quit();
        }

        public static int main (string[] args) {

            Intl.setlocale(LocaleCategory.ALL, "");
            Intl.textdomain(Config.GETTEXT_PACKAGE);
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALE_DIR);

            var context = new OptionContext("- " + _("Listen to your music"));
            context.set_summary(_("A web based music player that integrates your favourite music service into the desktop."));
            context.add_main_entries(mOptions, Config.GETTEXT_PACKAGE);

            try {
                context.parse(ref args);
            } catch (OptionError e) {
                stdout.printf("%s\n\n%s", e.message, context.get_help(true, null));
                return 1;
            }

            if(mShowVersion) {
                stdout.printf("%s %s\n", Config.PACKAGE, Config.VERSION);
                return 1;
            }

            //TODO
            /*if(mQueryService) {

                if(mService != null) {
                    //Preselect service
                } else {
                    //Use default
                }

                //TODO Check if search is supported for service

                stdout.printf("TODO\n");
                return 1;
            }*/

            if(mListServices) {
                Service[] services = Service.GetServices();

                foreach(Service service in services) {
                    if(service.Enabled) {
                        stdout.printf(service.to_string() + "\n");
                    }
                }
                return 1;
            }

            GtkClutter.init (ref args);
            Gtk.init(ref args);
            Gtk.IconTheme.get_default().append_search_path(Config.THEME_DIR);
            Gtk.Window.set_default_icon_name(Config.PACKAGE);

            WebMusic app = new WebMusic();
            return app.run(args);
        }
    }
}

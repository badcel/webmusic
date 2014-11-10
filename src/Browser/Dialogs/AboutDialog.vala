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

namespace WebMusic.Browser.Dialogs {

    private class AboutDialog {
        
        public static void Show(Gtk.Window? parent) {
        
            string path = Config.PKG_DATA_DIR + "/about.ini";
            var file = new KeyFile();
            string[] authors = null;
            
            try {
                file.load_from_file(path, KeyFileFlags.NONE);
                authors = file.get_string_list("About", "Authors");            
            } catch(Error e) {
                string err = "Could not load %s file to show about dialog. (%s)".printf(path, e.message);
                critical(err);
                ErrorDialog.run(err);
                return;
            }
            
            string comments = _("A web based music player that "
                                + "integrates your favourite music service into the desktop.") + "\n\n"
                                + _("Powered by WebKit %d.%d.%d\n").printf(
                                WebKit.Version.MAJOR,
                                WebKit.Version.MINOR,
                                WebKit.Version.MICRO);
                
            Gdk.Pixbuf logo = null;
            Gtk.IconTheme iconTheme = Gtk.IconTheme.get_default();
            try {
                logo = iconTheme.load_icon(Config.PACKAGE, 128, 0);
            } catch (Error e) {
                string err = "Could not load webmusic icon from icon theme. (%s)".printf(e.message);
                critical(err);
                ErrorDialog.run(err);
                return;
            }
            
            Gtk.show_about_dialog (parent,
                "program-name", _("WebMusic"),
                "version", Config.VERSION,
                "copyright", "Copyright © 2014 Marcel Tiede",
                "comments", comments,
                "logo", logo,
                "authors", authors,
                "website", WebMusic.HOMEPAGE,
                /* The string "translator-credits" is a special string used
                * to credit the translators of webmusic in the about box.
                *
                * Please translate it to the names and e-mail addresses
                * of all translators separted by a newline (\n).
                */
                //"translator-credits", _("translator-credits"),
                "license-type", Gtk.License.GPL_3_0,
                "wrap-license", true);
        }
    
    }

}

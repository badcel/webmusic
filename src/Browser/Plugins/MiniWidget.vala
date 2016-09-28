/*
 *   Copyright (C) 2016  Marcel Tiede
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

namespace WebMusic.Browser.Plugins {

    private class MiniWidget : GLib.Object, IPlugin {


        private bool enable = false;
        private IPlayer player;
        private MiniWindow mini_window;

        public MiniWidget() {

            mini_window = new MiniWindow();
            mini_window.set_keep_above(true);
            mini_window.stick();

            var screen = Gdk.Screen.get_default();
            if(screen != null) {
                var width = screen.get_width() - 150;
                var height = screen.get_height() - 50;
                mini_window.move(width, height);
            } else {
                warning("Could not determine screen size for mini window.");
            }
        }

        public bool Enable {
            get { return this.enable; }
            set {

                this.enable = value;

                if(value) {
                    mini_window.present();
                } else {
                    mini_window.hide();
                }

            }
         }

        public bool RegisterPlayer(IPlayer p) {
            player = p;
            player.PropertiesChanged.connect(OnPropertiesChanged);
            return true;
        }

        private void OnPropertiesChanged(HashTable<PlayerProperties,Variant> dict) {

            bool has_data = false;

            string artist    = "";
            string track     = "";
            string album     = "";
            string file      = "";

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

            if(dict.contains(PlayerProperties.ART_FILE_LOCAL)) {
                file = dict.get(PlayerProperties.ART_FILE_LOCAL).get_string();
                has_data = true;
            }

            if(has_data) {
                string by = artist.length > 0? _("by %s").printf(artist): "";
                string from = album.length > 0? _("from %s").printf(album): "";

                string seperator = "";
                if(by.length > 0 && from.length> 0) {
                    seperator = "\n";
                }

                mini_window.set_label(track, by + seperator + from);
                mini_window.set_album_art(file.replace("file://", ""));

                mini_window.resize(1,1);
            }
        }

        [GtkTemplate (ui = "/org/WebMusic/Browser/ui/mini-window.ui")]
        private class MiniWindow : Gtk.Window {

            [GtkChild]
            private Gtk.Image album_art;

            [GtkChild]
            private Gtk.Label top_label;

            [GtkChild]
            private Gtk.Label bottom_label;

            public MiniWindow() {
                this.button_press_event.connect(this.on_button_press);
            }

            public void set_album_art(string art_file) {

                var style_context = this.album_art.get_style_context();

                try {
                    if(art_file.length == 0) {

                        this.album_art.set_from_icon_name("media-optical-cd-audio", Gtk.IconSize.DIALOG);
                        style_context.add_class("missing-album-art");

                    } else {

                        if(style_context.has_class("missing-album-art")) {
                            style_context.remove_class("missing-album-art");
                        }

                        Gdk.Pixbuf pix = new Gdk.Pixbuf.from_file_at_size(art_file, 48, 48);
                        this.album_art.set_from_pixbuf(pix);
                    }
                } catch(Error e) {

                    this.album_art.set_from_icon_name("media-optical-cd-audio", Gtk.IconSize.DIALOG);
                    style_context.add_class("missing-album-art");

                    warning("Could not set image from pixbuf: %s (%s)", e.message, art_file);
                }
            }

            public void set_label(string top_label, string bottom_label) {
                this.top_label.set_text(top_label);
                this.top_label.set_tooltip_text(top_label);
                this.bottom_label.set_markup(bottom_label);
                this.bottom_label.set_tooltip_text(bottom_label.replace("\n", " "));
            }

            private bool on_button_press(Gdk.EventButton event) {
                this.begin_move_drag((int)event.button, (int)event.x_root, (int)event.y_root, event.time);
                return true;
            }

        }

    }

}

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

namespace WebMusic.Browser.Widgets {

    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/image-overlay.ui")]
    public class ImageOverlay : Gtk.Overlay {

        [GtkChild]
        private Gtk.Image image;

        public int width { get; set; }
        public int height { get; set; }

        private Gtk.StyleContext style_context;

        construct {
            this.width = -1;
            this.height = -1;

            this.style_context = this.image.get_style_context();
        }

        public void set_size(int width, int height) {
            this.width = width;
            this.height = height;

            this.set_size_request(this.width, this.height);
        }

        public void LoadStockIcon(string name) {
            try {
                Gtk.IconTheme theme = Gtk.IconTheme.get_default();
                Gdk.Pixbuf? pixbuf = theme.load_icon_for_scale(name, this.width, 1, Gtk.IconLookupFlags.FORCE_SIZE);

                if(pixbuf == null) {
                    critical("No icon named %s found in icon theme.", name);
                } else {
                    SetPixbuf(pixbuf);
                }
            } catch(Error e) {
                critical("Could not load stock icon %s. (%s)", name, e.message);
            }
        }

        public void LoadImage(string image_path) {
            try {
                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_size(image_path, this.width, this.height);
                SetPixbuf(pixbuf);
            } catch(Error e) {
                critical("Could not load pixbuf from path %s. (%s)", image_path, e.message);
            }
        }

        public void add_style_class(string class) {
            if(!style_context.has_class(class)) {
                this.style_context.add_class(class);
            }
        }

        public void remove_style_class(string class) {
            if(style_context.has_class(class)) {
                style_context.remove_class(class);
            }
        }

        private void SetPixbuf(Gdk.Pixbuf pixbuf) throws Error {
            image.set_from_pixbuf(pixbuf);

            if(this.width > 0 && this.height > 0) {
                this.set_size_request(this.width, this.height);
            } else {
                this.set_size_request(pixbuf.width, pixbuf.height);
            }
        }

    }

}

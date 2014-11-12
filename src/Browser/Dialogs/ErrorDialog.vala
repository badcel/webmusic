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

    private class ErrorDialog {

        public static void run(string message) {

            Gtk.MessageDialog msg = new Gtk.MessageDialog(null,
                    Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.OK, message);

            msg.response.connect ((response_id) => {
                msg.destroy();
            });

            msg.run();
        }

    }
}

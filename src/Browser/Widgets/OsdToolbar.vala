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

namespace WebMusic.Browser.Widgets {

    [GtkTemplate (ui = "/org/WebMusic/Browser/ui/osd-toolbar.ui")]
    public class OsdToolbar : Gtk.EventBox {

        private IPlayer player;
        private Service service;

        [GtkChild]
        private Gtk.Toolbar toolbar;

        [GtkChild]
        private Gtk.ToggleButton button_shuffle;

        [GtkChild]
        private RepeatButton button_repeat;

        [GtkChild]
        private Gtk.ToggleButton button_like;

        construct {
            this.enter_notify_event.connect(on_enter_notify_event);
            this.leave_notify_event.connect(on_leave_notify_event);
            this.toolbar.enter_notify_event.connect(on_enter_notify_event);
        }

        public void init(IPlayer p, Service s) {
            player = p;
            service = s;

            service.ServiceLoaded.connect(() => {
                this.init_buttons();
            });

            this.init_buttons();

            player.PropertiesChanged.connect(on_properties_changed);
        }

        private void init_buttons() {

            button_shuffle.active = player.Shuffle;
            button_shuffle.visible = service.SupportsShuffle;

            button_repeat.RepeatState = player.Repeat;
            button_repeat.visible = service.SupportsRepeat;

            button_like.active = player.Like;
            button_like.visible = service.SupportsLike;

            if(!service.SupportsRepeat
                && !service.SupportsShuffle
                && !service.SupportsLike) {
                toolbar.opacity = 0.0;
            } else {
                toolbar.opacity = 1.0;
            }
        }

        private bool on_enter_notify_event(Gdk.EventCrossing event) {
            if(toolbar.opacity == 1.0) {
                toolbar.set_state_flags(Gtk.StateFlags.NORMAL, true);
            }
            return true;
        }

        private bool on_leave_notify_event(Gdk.EventCrossing event) {
            if(toolbar.opacity == 1.0) {
                toolbar.set_state_flags(Gtk.StateFlags.INCONSISTENT, true);
            }
            return true;
        }

        [GtkCallback]
        private void on_button_shuffle_toggled() {
            player.Shuffle = button_shuffle.active;
        }

        [GtkCallback]
        private void on_button_like_toggled() {
            player.Like = button_like.active;
        }

        [GtkCallback]
        private void on_button_repeat_clicked() {
            player.Repeat = button_repeat.RepeatState;
        }

        private void on_properties_changed(HashTable<PlayerProperties, Variant> dict){

            if(dict.contains(PlayerProperties.CAN_SHUFFLE)) {
                button_shuffle.sensitive = dict.get(PlayerProperties.CAN_SHUFFLE).get_boolean();
            }

            if(dict.contains(PlayerProperties.SHUFFLE)) {
                button_shuffle.active = dict.get(PlayerProperties.SHUFFLE).get_boolean();
            }

            if(dict.contains(PlayerProperties.CAN_REPEAT)) {
                button_repeat.sensitive = dict.get(PlayerProperties.CAN_REPEAT).get_boolean();
            }

            if(dict.contains(PlayerProperties.REPEAT)) {
                button_repeat.RepeatState = (RepeatStatus)dict.get(PlayerProperties.REPEAT).get_int64();
            }

            if(dict.contains(PlayerProperties.CAN_LIKE)) {
                button_like.sensitive = dict.get(PlayerProperties.CAN_LIKE).get_boolean();
            }

            if(dict.contains(PlayerProperties.LIKE)) {
                button_like.active = dict.get(PlayerProperties.LIKE).get_boolean();
            }
        }
    }
}

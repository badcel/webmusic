/*
 *   Copyright (C) 2014, 2015  Marcel Tiede
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
using Notify;

namespace WebMusic.Browser.Plugins {

    private class Notificationn : GLib.Object, IPlugin {

        private Notify.Notification notification;
        private PlayerApi player;

        public bool Enable { get; set; }

        public Notificationn() {
            Notify.init("WebMusic");

            player = PlayerApi.get_instance();
            player.PropertiesChanged.connect(on_properties_changed);
        }

        private void on_properties_changed(HashTable<string,Variant> dict) {

            if(!this.Enable)
                return;

            if(!dict.contains(PlayerApi.Property.METADATA)) {
                return;
            }

            Metadata metadata = PlayerApi.get_instance().Metadata;

            string artists   = string.joinv (", ", metadata.Artists);
            string track     = metadata.Track;
            string album     = metadata.Album;
            string file_name = Config.PACKAGE; //desktop icon
            //string file_name = metadata.ArtFileLocal; //album art

            try {
                string nowPlaying = _("Now playing %s").printf(track) + " ";
                string by = artists.length > 0? _("by %s").printf(artists) + "\n": "";
                string from = album.length > 0? _("from %s").printf(album): "";
                string trackInfo = by + from;

                if(notification == null) {
                    notification = new Notify.Notification(nowPlaying, trackInfo, file_name);
                }
                else
                {
                    notification.clear_actions();
                    notification.clear_hints();
                    notification.update(nowPlaying, trackInfo, file_name);
                }

                if(player.CanGoPrevious)
                {
                    notification.add_action("media-skip-backward", _("Previous"), check_notification_action);
                }

                if(player.PlaybackStatus == PlayStatus.PLAY) {
                    notification.add_action("media-playback-pause", _("Pause"), check_notification_action);
                }

                if(player.CanGoNext)
                {
                    notification.add_action("media-skip-forward", _("Next"), check_notification_action);
                }

                notification.set_urgency(Notify.Urgency.LOW);
                notification.set_hint("desktop-entry", new Variant.string("webmusic"));
                notification.set_hint("transient", new Variant.boolean(true));
                notification.set_hint("action-icons", new Variant.boolean(true));
                notification.show();

            } catch(GLib.Error e) {
                warning("Could not show notification. (%s)", e.message);
            }
        }

        private void check_notification_action(Notify.Notification notification, string action) {
            switch(action) {
                case "media-skip-forward":
                    player.Next();
                    break;
                case "media-playback-pause":
                    player.Pause();
                    break;
                case "media-skip-backward":
                    player.Previous();
                    break;
                default:
                    warning("Unknown notification action: %s", action);
                    break;
            }

        }

    }
}

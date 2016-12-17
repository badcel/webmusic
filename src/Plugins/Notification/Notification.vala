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

namespace WebMusic.Plugins.Notification {

    public class Notification: Object, PlayerPlugin {

        private Notify.Notification notification;
        public PlayerApi player_api { get; construct set; }
        public PlaylistApi playlist_api { get; construct set; }

        construct {
            Notify.init("WebMusic");
        }

        public void activate() {
            player_api.PropertiesChanged.connect(on_properties_changed);
        }

        public void deactivate() {
            player_api.PropertiesChanged.disconnect(on_properties_changed);
        }

        public void on_properties_changed(HashTable<string,Variant> dict) {

            if(!dict.contains(PlayerApi.Property.METADATA)) {
                return;
            }

            Metadata metadata = player_api.Metadata;

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

                if(player_api.CanGoPrevious)
                {
                    notification.add_action("media-skip-backward", _("Previous"), check_notification_action);
                }

                if(player_api.PlaybackStatus == PlayStatus.PLAY) {
                    notification.add_action("media-playback-pause", _("Pause"), check_notification_action);
                }

                if(player_api.CanGoNext)
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
                    player_api.Next();
                    break;
                case "media-playback-pause":
                    player_api.Pause();
                    break;
                case "media-skip-backward":
                    player_api.Previous();
                    break;
                default:
                    warning("Unknown notification action: %s", action);
                    break;
            }

        }
    }
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof (PlayerPlugin),
	    typeof (WebMusic.Plugins.Notification.Notification));
}

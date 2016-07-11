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

        private Notify.Notification mNotification;
        private IPlayer mPlayer;

        public bool Enable { get; set; }

        public Notificationn() {
            Notify.init("WebMusic");
        }

        public bool RegisterPlayer(IPlayer player) {
            mPlayer = player;
            mPlayer.PropertiesChanged.connect(OnPropertiesChanged);
            return true;
        }

        private void OnPropertiesChanged(HashTable<PlayerProperties,Variant> dict) {

            bool has_data = false;

            string artist    = "";
            string track     = "";
            string album     = "";
            string file_name = Config.PACKAGE; //desktop icon

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

            //if(dict.contains(PlayerProperties.ART_FILE_LOCAL)) {
            //    file_name = dict.get(PlayerProperties.ART_FILE_LOCAL).get_string();
            //}

            if(!this.Enable || !has_data)
                return;

            try {
                string nowPlaying = _("Now playing %s").printf(track) + " ";
                string by = artist.length > 0? _("by %s").printf(artist) + "\n": "";
                string from = album.length > 0? _("from %s").printf(album): "";
                string trackInfo = by + from;

                if(mNotification == null) {
                    mNotification = new Notify.Notification(nowPlaying, trackInfo, file_name);
                }
                else
                {
                    mNotification.clear_actions();
                    mNotification.clear_hints();
                    mNotification.update(nowPlaying, trackInfo, file_name);
                }

                if(mPlayer.CanGoPrevious)
                {
                    mNotification.add_action("media-skip-backward", _("Previous"), CheckNotificationAction);
                }

                if(mPlayer.PlaybackStatus == PlayStatus.PLAY) {
                    mNotification.add_action("media-playback-pause", _("Pause"), CheckNotificationAction);
                }

                if(mPlayer.CanGoNext)
                {
                    mNotification.add_action("media-skip-forward", _("Next"), CheckNotificationAction);
                }

                mNotification.set_urgency(Notify.Urgency.LOW);
                mNotification.set_hint("desktop-entry", new Variant.string("webmusic"));
                mNotification.set_hint("transient", new Variant.boolean(true));
                mNotification.set_hint("action-icons", new Variant.boolean(true));
                mNotification.show();

            } catch(GLib.Error e) {
                critical("Could not prepare notification. (%s)", e.message);
            }
        }

        private void CheckNotificationAction(Notify.Notification notification, string action) {
            switch(action) {
                case "media-skip-forward":
                    try {
                        mPlayer.Next();
                    } catch(GLib.IOError e) {
                        warning("Could not execute 'next' command due to a dbus error. (%s)", e.message);
                    }
                    break;
                case "media-playback-pause":
                    try {
                        mPlayer.Pause();
                    } catch(GLib.IOError e) {
                        warning("Could not execute 'pause' command due to a dbus error. (%s)", e.message);
                    }
                    break;
                case "media-skip-backward":
                    try {
                        mPlayer.Previous();
                    } catch(GLib.IOError e) {
                        warning("Could not execute 'previous' command due to a dbus error. (%s)", e.message);
                    }
                    break;
                default:
                    warning("Unknown notification action: %s", action);
                    break;
            }

        }

    }
}

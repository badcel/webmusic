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
using WebMusic.Webextension;
using Notify;

namespace WebMusic.Webextension.Plugins {

    private class Notification : GLib.Object, IPlugin {

        private Notify.Notification mNotification;
        private Player mPlayer;

        public bool Enable { get; set; }

        public Notification() {
            Notify.init("WebMusic");
        }

        public bool RegisterPlayer(Player player) {
            mPlayer = player;
            mPlayer.MetadataChanged.connect(OnMetadataChanged);
            return true;
        }

        private void OnMetadataChanged(string url, string artist, string track, string album,
                                        string fileName, int64 length){

            if(!this.Enable)
                return;

            try {
                string f = fileName.replace("file://", "");

                string nowPlaying = _("Now playing %s").printf(track) + " ";
                string by = artist.length > 0? _("by %s").printf(artist) + "\n": "";
                string from = album.length > 0? _("from %s").printf(album): "";
                string trackInfo = by + from;

                if(mNotification == null) {
                    mNotification = new Notify.Notification(nowPlaying, trackInfo, "webmusic");
                }
                else
                {
                    mNotification.clear_actions();
                    mNotification.clear_hints();
                    mNotification.update(nowPlaying, trackInfo, "webmusic");
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

                if(f.length > 0) {
                    Gdk.Pixbuf pix = new Gdk.Pixbuf.from_file(f);
                    mNotification.set_image_from_pixbuf(pix);
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
                    mPlayer.Next();
                    break;
                case "media-playback-pause":
                    mPlayer.Pause();
                    break;
                case "media-skip-backward":
                    mPlayer.Previous();
                    break;
                default:
                    warning("Unknown notification action: %s", action);
                    break;
            }

        }

    }
}

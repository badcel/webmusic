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

namespace LibWebMusic {

    public enum PlayStatus {
        STOP,   // INT = 0
        PLAY,   // INT = 1
        PAUSE;  // INT = 2

        public string to_string() {

            //Strings are compatible to the MPRIS dbus-specification.
            //Do not change!

            string ret = "";

            switch(this) {
                case PlayStatus.STOP:
                    ret = "Stopped";
                    break;
                case PlayStatus.PLAY:
                    ret = "Playing";
                    break;
                case PlayStatus.PAUSE:
                    ret = "Paused";
                    break;
            }

            return ret;
        }
    }

    public enum RepeatStatus {
        NONE,     // INT = 0
        PLAYLIST, // INT = 1
        TRACK;    // INT = 2

        public string to_string() {

            //Strings are compatible to the MPRIS dbus-specification.
            //Do not change!

            string ret = "";

            switch(this) {
                case RepeatStatus.NONE:
                    ret = "None";
                    break;
                case RepeatStatus.TRACK:
                    ret = "Track";
                    break;
                case RepeatStatus.PLAYLIST:
                    ret = "Playlist";
                    break;
            }

            return ret;
        }

        public static bool try_parse_name(string name, out RepeatStatus result = null) {

            bool ret = true;
            switch(name) {
                case "None":
                    result = RepeatStatus.NONE;
                    break;
                case "Track":
                    result = RepeatStatus.TRACK;
                    break;
                case "Playlist":
                    result = RepeatStatus.PLAYLIST;
                    break;
                default:
                    result = RepeatStatus.NONE;
                    ret = false;
                    break;
            }

            return ret;
        }

        public static uint n_values() {
            EnumClass enumc = (EnumClass)typeof(RepeatStatus).class_ref();
    		return enumc.n_values;
        }
    }

    [DBus(name = "org.WebMusic.Webextension.Player")]
    public interface IPlayer : GLib.Object {

        public signal void MetadataChanged(string artist, string track, string album,
                                            string artUrl, int64 length);
        public signal void PlayercontrolChanged(bool canGoNext, bool canGoPrev, bool canShuffle,
                                                bool canRepeat, bool shuffle, bool like,
                                                PlayStatus playStatus, RepeatStatus repeat);

        public abstract bool   Shuffle        { get; set; }
        public abstract bool   Like           { get; set; }
        public abstract RepeatStatus Repeat   { get; set; }

        public abstract void Next()     throws IOError;
        public abstract void Previous() throws IOError;
        public abstract void Pause()    throws IOError;
        public abstract void Stop()     throws IOError;
        public abstract void Play()     throws IOError;

        public abstract void PlayPause() throws IOError;
    }
}

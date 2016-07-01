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

    public enum PlayerProperties {
        READY,           // INT =  0
        CAN_CONTROL,     // INT =  1
        CAN_PLAY,        // INT =  2
        CAN_PAUSE,       // INT =  3
        CAN_SEEK,        // INT =  4
        CAN_GO_NEXT,     // INT =  5
        CAN_GO_PREVIOUS, // INT =  6
        CAN_SHUFFLE,     // INT =  7
        CAN_REPEAT,      // INT =  8
        URL,             // INT =  9
        ARTIST,          // INT = 10
        TRACK,           // INT = 11
        ALBUM,           // INT = 12
        ART_URL,         // INT = 13
        ART_FILE_LOCAL,  // INT = 14
        PLAYBACKSTATUS,  // INT = 15
        LIKE,            // INT = 16
        SHUFFLE,         // INT = 17
        REPEAT,          // INT = 18
        VOLUME,          // INT = 19
        TRACK_LENGTH,    // INT = 20
        TRACK_POSITION;  // INT = 21

        public static bool try_parse_name(string name, out PlayerProperties? result) {

            bool ret = true;
            switch(name) {
                case "ready":
                    result = PlayerProperties.READY;
                    break;
                case "canControl":
                    result = PlayerProperties.CAN_CONTROL;
                    break;
                case "canPlay":
                    result = PlayerProperties.CAN_PLAY;
                    break;
                case "canPause":
                    result = PlayerProperties.CAN_PAUSE;
                    break;
                case "canSeek":
                    result = PlayerProperties.CAN_SEEK;
                    break;
                case "canGoNext":
                    result = PlayerProperties.CAN_GO_NEXT;
                    break;
                case "canGoPrevious":
                    result = PlayerProperties.CAN_GO_PREVIOUS;
                    break;
                case "canShuffle":
                    result = PlayerProperties.CAN_SHUFFLE;
                    break;
                case "canRepeat":
                    result = PlayerProperties.CAN_REPEAT;
                    break;
                case "url":
                    result = PlayerProperties.URL;
                    break;
                case "artist":
                    result = PlayerProperties.ARTIST;
                    break;
                case "track":
                    result = PlayerProperties.TRACK;
                    break;
                case "album":
                    result = PlayerProperties.ALBUM;
                    break;
                case "artUrl":
                    result = PlayerProperties.ART_URL;
                    break;
                case "artFileLocal":
                    result = PlayerProperties.ART_FILE_LOCAL;
                    break;
                case "playbackstatus":
                    result = PlayerProperties.PLAYBACKSTATUS;
                    break;
                case "like":
                    result = PlayerProperties.LIKE;
                    break;
                case "shuffle":
                    result = PlayerProperties.SHUFFLE;
                    break;
                case "repeat":
                    result = PlayerProperties.REPEAT;
                    break;
                case "volume":
                    result = PlayerProperties.VOLUME;
                    break;
                case "trackLength":
                    result = PlayerProperties.TRACK_LENGTH;
                    break;
                case "trackPosition":
                    result = PlayerProperties.TRACK_POSITION;
                    break;
                default:
                    result = null;
                    ret = false;
                    break;
            }

            return ret;
        }

    }

    [DBus(name = "org.WebMusic.Webextension.Player")]
    public interface IPlayer : GLib.Object {

        public signal void MetadataChanged(string url, string artist, string track, string album,
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

        public abstract void Search(string term) throws IOError;
        public abstract void Show(string type, string id) throws IOError;
    }
}

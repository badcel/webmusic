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

    [DBus (use_string_marshalling = true)]
    public enum PlayStatus {

        [DBus (value = "Stopped")]
        STOP,   // INT = 0
        [DBus (value = "Playing")]
        PLAY,   // INT = 1
        [DBus (value = "Paused")]
        PAUSE;  // INT = 2
    }

    [DBus (use_string_marshalling = true)]
    public enum RepeatStatus {

        [DBus (value = "None")]
        NONE,     // INT = 0
        [DBus (value = "Playlist")]
        PLAYLIST, // INT = 1
        [DBus (value = "Track")]
        TRACK;    // INT = 2

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
                case "playbackStatus":
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

    public interface IPlayerPropertiesChangedProvider : GLib.Object {

        public HashTable<string, Variant> get_properties_changed_data(HashTable<PlayerProperties, Variant> dict, out bool has_metadata) {

            HashTable<string, Variant> data = new HashTable<string, Variant>(str_hash, str_equal);
            bool _has_metadata = false;

            dict.foreach ((key, val) => {
                switch(key) {
                    case PlayerProperties.CAN_CONTROL:
                        data.insert("CanControl", val);
                        break;
                    case PlayerProperties.CAN_PLAY:
                        data.insert("CanPlay", val);
                        break;
                    case PlayerProperties.CAN_PAUSE:
                        data.insert("CanPause", val);
                        break;
                    case PlayerProperties.CAN_SEEK:
                        data.insert("CanSeek", val);
                        break;
                    case PlayerProperties.CAN_GO_NEXT:
                        data.insert("CanGoNext", val);
                        break;
                    case PlayerProperties.CAN_GO_PREVIOUS:
                        data.insert("CanGoPrevious", val);
                        break;
                    case PlayerProperties.CAN_SHUFFLE:
                        data.insert("CanShuffle", val);
                        break;
                    case PlayerProperties.CAN_REPEAT:
                        data.insert("CanRepeat", val);
                        break;
                    case PlayerProperties.PLAYBACKSTATUS:
                        data.insert("PlaybackStatus", (PlayStatus) val.get_double());
                        break;
                    case PlayerProperties.SHUFFLE:
                        data.insert("Shuffle", val);
                        break;
                    case PlayerProperties.REPEAT:
                        data.insert("LoopStatus", (RepeatStatus) val.get_double());
                        break;
                    case PlayerProperties.VOLUME:
                        data.insert("Volume", val);
                        break;
                    case PlayerProperties.URL:
                    case PlayerProperties.ARTIST:
                    case PlayerProperties.TRACK:
                    case PlayerProperties.ALBUM:
                    case PlayerProperties.ART_URL:
                    case PlayerProperties.TRACK_LENGTH:
                        _has_metadata = true;
                        break;
                }
	        });

            has_metadata = _has_metadata;
            return data;
        }

    }

    [DBus (name = "org.WebMusic.Webextension.Player")]
    public interface IPlayer : GLib.Object {

        public signal void PropertiesChanged(HashTable<PlayerProperties, Variant> dict);
        public signal void Seeked(int64 position);

        public abstract bool   Shuffle        { get; set; }
        public abstract bool   Like           { get; set; }
        public abstract RepeatStatus Repeat   { get; set; }
        public abstract PlayStatus   PlaybackStatus { get; }

        public abstract void Next()     throws IOError;
        public abstract void Previous() throws IOError;
        public abstract void Pause()    throws IOError;
        public abstract void Stop()     throws IOError;
        public abstract void Play()     throws IOError;

        public abstract void PlayPause() throws IOError;

        public abstract bool CanGoNext      { get; }
        public abstract bool CanGoPrevious  { get; }
        public abstract bool CanPlay        { get; }
        public abstract bool CanPause       { get; }
        public abstract bool CanSeek        { get; }
        public abstract bool CanControl     { get; }
        public abstract bool CanShuffle     { get; }
        public abstract bool CanRepeat      { get; }

        public abstract double Volume       { get; set; }
        public abstract int64  Position     { get; set; }

        public abstract void Search(string term) throws IOError;
        public abstract void Show(string type, string id) throws IOError;
    }
}

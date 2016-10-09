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

    public class PlayerApi : BaseApi {

        private static PlayerApi player_api;

        private bool shuffle = false;
        private bool like    = false;

        public signal void PropertiesChanged(HashTable<string, Variant> dict);
        public signal void Seeked(int64 position);

        public PlayerApi() {
            base(ObjectType.PLAYER);
        }

        public static PlayerApi get_instance() {
            if(player_api == null) {
                player_api = new PlayerApi();
            }

            return player_api;
        }

        public bool CanControl {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_CONTROL);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanPlay {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_PLAY);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanPause {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_PAUSE);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanSeek {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_SEEK);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanGoNext {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_GO_NEXT);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanGoPrevious {
            get {

                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_GO_PREVIOUS);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanShuffle {
            get {
                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_SHUFFLE);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanRepeat {
            get {
                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_REPEAT);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public bool CanLike {
            get {
                bool ret = false;

                var prop = this.get_adapter_property(Property.CAN_LIKE);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                return ret;
            }
        }

        public PlayStatus PlaybackStatus {
            get {
                PlayStatus ret = PlayStatus.STOP;

                var prop = this.get_adapter_property(Property.PLAYBACKSTATUS);
                if(prop != null && prop.is_of_type(VariantType.INT64)) {
                    ret = (PlayStatus) prop.get_int64();
                }

                return ret;
            }
        }

        public bool Like {
            get {
                bool ret = false;

                var prop = this.get_adapter_property(Property.LIKE);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                this.like = ret;
                return ret;
            }
            set {
                if(this.Like != value) {
                    this.call_adapter_function(Action.TOGGLE_LIKE, null);
                }
            }
        }

        public bool Shuffle {
            get {
                bool ret = false;

                var prop = this.get_adapter_property(Property.SHUFFLE);
                if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                    ret = prop.get_boolean();
                }

                this.shuffle = ret;
                return ret;
            }
            set {
                if(this.Shuffle != value) {
                    this.call_adapter_function(Action.TOGGLE_SHUFFLE, null);
                }
            }
        }

        public RepeatStatus Repeat {
            get {
                RepeatStatus repeat = RepeatStatus.NONE;

                var prop = this.get_adapter_property(Property.REPEAT);
                if(prop != null && prop.is_of_type(VariantType.DOUBLE)) {
                    repeat = (RepeatStatus) prop.get_double();
                }

                return repeat;
            }
            set {
                Variant[] args = new Variant[1];
                args[0] = new Variant.int64((int64)value);

                this.call_adapter_function(Action.REPEAT, args);
            }
        }

        public double Volume {
            get {
                double ret = 1;

                var prop = this.get_adapter_property(Property.VOLUME);
                if(prop != null && prop.is_of_type(VariantType.DOUBLE)) {
                    ret = prop.get_double();
                }

                return ret;
            }
            set {
                Variant[] args = new Variant[1];
                args[0] = new Variant.double(value);

                this.call_adapter_function(Action.VOLUME, args);
            }
        }

        public int64 Position {
            get {
                int64 ret = 0;

                if(api.Ready) {
                    //Directly call api, to prevent caching of this property
                    Variant? prop = api.get_adapter_property(ObjectType.PLAYER, Property.TRACK_POSITION);
                    if(prop != null && prop.is_of_type(VariantType.INT64)) {
                        ret = prop.get_int64();
                    }
                }

                return ret;
            }
            set {
                Variant[] args = new Variant[1];
                args[0] = new Variant.int64(value);

                this.call_adapter_function(Action.TRACK_POSITION, args);
            }
        }

        public void Stop() {
            this.call_adapter_function(Action.STOP, null);
        }

        public void Play() {
            this.call_adapter_function(Action.PLAY, null);

            //Manually send seeked signal to avoid desync
            this.Seeked(this.Position);
        }

        public void Pause() {
            this.call_adapter_function(Action.PAUSE, null);
        }

        public void PlayPause() {
            if(this.PlaybackStatus != PlayStatus.PLAY) {
                this.Play();
            } else {
                this.Pause();
            }
        }

        public void Next() {
            this.call_adapter_function(Action.NEXT, null);
        }

        public void Previous() {
            this.call_adapter_function(Action.PREVIOUS, null);
        }

        public void Show(string type, string id) {

            Variant[] args = new Variant[2];
            args[0] = new Variant.string(type);
            args[1] = new Variant.string(id);

            this.call_adapter_function(BrowserAction.SHOW, args);
        }

        public void Search(string term) {

            Variant[] args = new Variant[1];
            args[0] = new Variant.string(term);

            this.call_adapter_function(BrowserAction.SEARCH, args);
        }

        protected override void signal_send(string signal_name, Variant? parameter) {
            if(signal_name == "seeked"
                && parameter != null && parameter.is_of_type(VariantType.INT64)) {
                this.Seeked(parameter.get_int64());
            }
        }

        protected override void properties_changed(HashTable<string, Variant> changes) {

            if(changes.contains(PlayerApi.Property.ART_URL)) {
                this.cache_cover(changes);
            } else {
                this.PropertiesChanged(changes);
            }
        }

        private void cache_cover(HashTable<string, Variant> changes) {

            string art_url = changes.get(Property.ART_URL).get_string();

            string artist = "";
            if(changes.contains(Property.ARTIST)) {
                artist = changes.get(Property.ARTIST).get_string();
            }

            string album = "";
            if(changes.contains(Property.ALBUM)) {
                album = changes.get(Property.ALBUM).get_string();
            }

            string track = "";
            if(changes.contains(Property.TRACK)) {
                track = changes.get(Property.TRACK).get_string();
            }

            string url_extension = art_url.substring(art_url.last_index_of_char('.'));
            string file_artist   = artist.length > 0 ? artist + "_" : "";
            string file_album    = album.length  > 0 ? album : track;

            if(file_album.length == 0) {
                //No track or album given. Generate id which is useable only one time
                string date = new DateTime.now_utc().to_string();
                file_album = GLib.Checksum.compute_for_string(ChecksumType.MD5, date, date.length);
            }

            string file_name = (file_artist + file_album + url_extension).replace(" ", "_").replace("/", "_");
            file_name = Directory.GetAlbumArtDir() + file_name;

            var file_cache = new FileCache();

            file_cache.file_cached.connect((file_name, success) => {

                if(success) {
                    changes.insert(Property.ART_FILE_LOCAL, new Variant.string("file://" + file_name));
                }

                this.PropertiesChanged(changes);
            });

           file_cache.cache_async(art_url, file_name);
        }

        public class Property {
            public const string READY           = "ready";
            public const string CAN_CONTROL     = "canControl";
            public const string CAN_PLAY        = "canPlay";
            public const string CAN_PAUSE       = "canPause";
            public const string CAN_SEEK        = "canSeek";
            public const string CAN_GO_NEXT     = "canGoNext";
            public const string CAN_GO_PREVIOUS = "canGoPrevious";
            public const string CAN_SHUFFLE     = "canShuffle";
            public const string CAN_REPEAT      = "canRepeat";
            public const string CAN_LIKE        = "canLike";
            public const string URL             = "url";
            public const string ARTIST          = "artist";
            public const string TRACK           = "track";
            public const string ALBUM           = "album";
            public const string ART_URL         = "artUrl";
            public const string ART_FILE_LOCAL  = "artFileLocal";
            public const string PLAYBACKSTATUS  = "playbackStatus";
            public const string LIKE            = "like";
            public const string SHUFFLE         = "shuffle";
            public const string REPEAT          = "repeat";
            public const string VOLUME          = "volume";
            public const string TRACK_LENGTH    = "trackLength";
            public const string TRACK_POSITION  = "trackPosition";
        }

        private class Action {
            public const string STOP            = "actionStop";
            public const string PLAY            = "actionPlay";
            public const string PAUSE           = "actionPause";
            public const string PLAY_PAUSE      = "actionPlayPause";
            public const string NEXT            = "actionNext";
            public const string PREVIOUS        = "actionPrevious";
            public const string REPEAT          = "actionRepeat";
            public const string VOLUME          = "actionVolume";
            public const string TRACK_POSITION  = "actionTrackPosition";
            public const string TOGGLE_SHUFFLE  = "actionToggleShuffle";
            public const string TOGGLE_LIKE     = "actionToggleLike";
        }

        private class BrowserAction {
            public const string SEARCH  = "actionSearch";
            public const string SHOW    = "actionShow";
        }

    }
}

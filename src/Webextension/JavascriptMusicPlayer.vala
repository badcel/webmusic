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
using WebMusic.Webextension.JsInterface;

namespace WebMusic.Webextension {

    public enum BrowserAction {
        SEARCH, // INT = 0
        SHOW;   // INT = 1

        public string to_string() {

            string ret = "";

            switch(this) {
                case BrowserAction.SEARCH:
                    ret = "actionSearch";
                    break;
                case BrowserAction.SHOW:
                    ret = "actionShow";
                    break;
            }

            return ret;
        }
    }

    public enum PlayerAction {

        STOP,           // INT = 0
        PLAY,           // INT = 1
        PAUSE,          // INT = 2
        NEXT,           // INT = 3
        PREVIOUS,       // INT = 4
        REPEAT,         // INT = 5
        VOLUME,         // INT = 6
        TRACK_POSITION, // INT = 7
        TOGGLE_SHUFFLE, // INT = 8
        TOGGLE_LIKE;    // INT = 9

        public string to_string() {

            string ret = "";

            switch(this) {
                case PlayerAction.STOP:
                    ret = "actionStop";
                    break;
                case PlayerAction.PLAY:
                    ret = "actionPlay";
                    break;
                case PlayerAction.PAUSE:
                    ret = "actionPause";
                    break;
                case PlayerAction.NEXT:
                    ret = "actionNext";
                    break;
                case PlayerAction.PREVIOUS:
                    ret = "actionPrevious";
                    break;
                case PlayerAction.REPEAT:
                    ret = "actionRepeat";
                    break;
                case PlayerAction.VOLUME:
                    ret = "actionVolume";
                    break;
                case PlayerAction.TRACK_POSITION:
                    ret = "actionTrackPosition";
                    break;
                case PlayerAction.TOGGLE_SHUFFLE:
                    ret = "actionToggleShuffle";
                    break;
                case PlayerAction.TOGGLE_LIKE:
                    ret = "actionToggleLike";
                    break;
            }

            return ret;
        }
    }

    [DBus(name = "org.WebMusic.Webextension.Player")]
    private class JavascriptMusicPlayer : Player, IJsAdapter {

        private JsApi js_api;

        private bool mShuffle = false;
        private bool mLike = false;

        public JavascriptMusicPlayer() {
        }

        [DBus (visible = false)]
        public void insert_js_api(JsApi api) {
            js_api = api;
            js_api.SignalSend.connect(on_signal_send);
        }

        private Variant? activate_action(PlayerAction action, Variant[]? args) {

            Variant? parameter = null;
            if(args != null) {
                if(args.length == 1) {
                    parameter = args[0];
                } else if(args.length > 1){
                    parameter = new Variant.array(null, args);
                }
            }

            var command = new JsCommand(JsObjectType.PLAYER, JsAction.CALL_FUNCTION,
                            action.to_string(), parameter);
            return js_api.send_command(command);
        }

        private Variant? activate_browser_action(BrowserAction action, Variant[]? args) {

            //TODO Validate if "BrowserAction" belongs into a separate feature like player / playlist

            Variant? parameter = null;
            if(args != null) {
                if(args.length == 1) {
                    parameter = args[0];
                } else if(args.length > 1){
                    parameter = new Variant.array(null, args);
                }
            }

            var command = new JsCommand(JsObjectType.PLAYER, JsAction.CALL_FUNCTION,
                            action.to_string(), parameter);
            return js_api.send_command(command);
        }

        private Variant? get_js_property(string name){
            var command = new JsCommand(JsObjectType.PLAYER, JsAction.GET_PROPERTY, name, null);
            return js_api.send_command(command);
        }

        private void on_signal_send(JsObjectType type, string name, Variant? params) {
            if(type != JsObjectType.PLAYER) {
                return;
            }

            if(params == null) {
                warning("Missing parameters to send signal <%s>.", name);
                return;
            }

            if(name == "seeked") {

                if(params.is_of_type(VariantType.INT64)) {
                    this.Seeked(params.get_int64());
                } else {
                    warning("Can not send Seeked signal. Parameter is not of type int64, but <%s>.", params.get_type_string());
                }

            } else if(name == "propertiesChanged") {

                if(!params.is_of_type(VariantType.DICTIONARY)) {
                    warning("Can not send PropertiesChanged signal. Parameter is not of type dictionary.");
                    return;
                }

                HashTable<PlayerProperties, Variant> changes = new HashTable<PlayerProperties, Variant>(direct_hash, direct_equal);
                PlayerProperties? prop = null;

                //Convert changes into enum types
                HashTable<string, Variant> dict = (HashTable<string, Variant>) params;
	            dict.foreach ((key, val) => {
		            if(PlayerProperties.try_parse_name(key, out prop)) {
		                changes.insert(prop, val);
		            } else {
		                warning("Failed to parse javascript player property: %s", key);
		            }
	            });

            	if(changes.contains(PlayerProperties.ART_URL)) {
                    cache_cover(changes);
	            } else {
                    this.send_property_change(changes);
	            }
            }
        }

        private void cache_cover(HashTable<PlayerProperties, Variant> changes) {

            string art_url = changes.get(PlayerProperties.ART_URL).get_string();

            string artist = "";
            if(changes.contains(PlayerProperties.ARTIST)) {
                artist = changes.get(PlayerProperties.ARTIST).get_string();
            }

            string album = "";
            if(changes.contains(PlayerProperties.ALBUM)) {
                album = changes.get(PlayerProperties.ALBUM).get_string();
            }

            string track = "";
            if(changes.contains(PlayerProperties.TRACK)) {
                track = changes.get(PlayerProperties.TRACK).get_string();
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
                    changes.insert(PlayerProperties.ART_FILE_LOCAL, new Variant.string("file://" + file_name));
                }

                this.send_property_change(changes);
            });

           file_cache.cache_async(art_url, file_name);
        }

        public override PlayStatus PlaybackStatus {
            get {
                if(js_api.Ready) {
                    var prop = this.get_js_property("playbackStatus");
                    if(prop != null && prop.is_of_type(VariantType.INT64)) {
                        return (PlayStatus) prop.get_int64();
                    } else {
                        return PlayStatus.STOP;
                    }
                } else {
                    return PlayStatus.STOP;
                }
            }
        }

        public override bool CanGoNext {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canGoNext");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanGoPrevious {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canGoPrevious");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }


        public override bool CanPlay {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canPlay");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanPause {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canPause");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanSeek {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canSeek");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanControl {
            get {

                bool ret = false;

                if(js_api.Ready) {
                    var prop = this.get_js_property("canControl");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }
                return ret;
            }
        }

        public override bool Shuffle {
            get {
                bool ret = false;

                if(js_api.Ready && js_api.WebService.SupportsShuffle) {
                    var prop = this.get_js_property("shuffle");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }
                mShuffle = ret;
                return ret;
            }
            set {
                if(js_api.Ready && js_api.WebService.SupportsShuffle && this.Shuffle != value) {
                    this.activate_action(PlayerAction.TOGGLE_SHUFFLE, null);
                }
            }
        }

        public override bool Like {
            get {
                bool ret = false;

                if(js_api.Ready && js_api.WebService.SupportsLike) {
                    var prop = this.get_js_property("like");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }
                mLike = ret;
                return ret;
            }
            set {
                if(js_api.Ready && js_api.WebService.SupportsLike && this.Like != value) {
                    Idle.add(() => {
                        this.activate_action(PlayerAction.TOGGLE_LIKE, null);
                        return false;
                    });
                }
            }
        }

        public override double Volume {
            get {
                double ret = 1;

                if(js_api.Ready) {
                    var prop = this.get_js_property("volume");
                    if(prop != null && prop.is_of_type(VariantType.DOUBLE)) {
                        ret = prop.get_double();
                    }
                }
                return ret;
            }
            set {
                if(js_api.Ready) {
                    Idle.add(() => {
                        Variant[] args = new Variant[1];
                        args[0] = new Variant.double(value);
                        this.activate_action(PlayerAction.VOLUME, args);
                        return false;
                    });
                }
            }
        }

        public override int64 Position {
            get {
                int64 ret = 0;

                if(js_api.Ready) {
                    var prop = this.get_js_property("trackPosition");
                    if(prop != null && prop.is_of_type(VariantType.DOUBLE)) {
                        ret = (int64) prop.get_double();
                    }
                }
                return ret;
            }
            set {
                if(js_api.Ready) {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.int64(value);
                    this.activate_action(PlayerAction.TRACK_POSITION, args);
                }
            }
        }

        public override bool CanShuffle {
            get {
                bool ret = false;

                if(js_api.Ready && js_api.WebService.SupportsShuffle) {
                    var prop = this.get_js_property("canShuffle");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanRepeat {
            get {
                bool ret = false;

                if(js_api.Ready && js_api.WebService.SupportsRepeat) {
                    var prop = this.get_js_property("canRepeat");
                    if(prop != null && prop.is_of_type(VariantType.BOOLEAN)) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override RepeatStatus Repeat {
            get {
                RepeatStatus repeat = RepeatStatus.NONE;
                if(js_api.Ready && js_api.WebService.SupportsRepeat) {
                    var prop = this.get_js_property("repeat");
                    if(prop != null && prop.is_of_type(VariantType.DOUBLE)) {
                        repeat = (RepeatStatus) prop.get_double();
                    }
                }
                return repeat;
            }
            set {
                if(js_api.Ready && js_api.WebService.SupportsRepeat) {
                    Idle.add(() => {
                        Variant[] args = new Variant[1];
                        args[0] = new Variant.int64((int64)value);
                        this.activate_action(PlayerAction.REPEAT, args);
                        return false;
                    });
                }
            }
        }

        public override void Next() {
            if(js_api.Ready) {
                Idle.add(() => {
                    this.activate_action(PlayerAction.NEXT, null);
                    return false;
                });
            }
        }

        public override void Previous() {
            if(js_api.Ready) {
                Idle.add(() => {
                    this.activate_action(PlayerAction.PREVIOUS, null);
                    return false;
                });
            }
        }

        public override void Pause() {
            if(js_api.Ready) {
                Idle.add(() => {
                    this.activate_action(PlayerAction.PAUSE, null);
                    return false;
                });
            }
        }

        public override void Stop() {
            if(js_api.Ready) {
                Idle.add(() => {
                    this.activate_action(PlayerAction.STOP, null);
                    return false;
                });
            }
        }

        public override void Play() {
            if(js_api.Ready) {
                Idle.add(() => {
                    this.activate_action(PlayerAction.PLAY, null);
                    return false;
                });
            }
        }

        public override void Search(string term) {

            if(js_api.Ready) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string(term);
                    this.activate_browser_action(BrowserAction.SEARCH, args);
                    return false;
                });
            }
        }

        public override void Show(string type, string id) {
            if(js_api.Ready) {
                Idle.add(() => {
                    Variant[] args = new Variant[2];
                    args[0] = new Variant.string(type);
                    args[1] = new Variant.string(id);
                    this.activate_browser_action(BrowserAction.SHOW, args);
                    return false;
                });
            }
        }


    }
}

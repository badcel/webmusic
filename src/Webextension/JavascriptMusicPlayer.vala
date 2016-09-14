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
    private class JavascriptMusicPlayer : Player {

        private const int REQUIRED_API_VERSION = 1;
        private static const string API_NAME = "WebMusicApi";
        private static JavascriptMusicPlayer? mSelf = null;

        private JsObject mContext;
        private JsObject mJsPlayer;

        private Service mService;
        private bool mIntegrationReady = false;
        private bool mShuffle = false;
        private bool mLike = false;

        public JavascriptMusicPlayer(Service service) {
            mService = service;

            mContext = new JsObject();
            mContext.ContextChanged.connect(OnContextChanged);

            mSelf = this;
        }

        private static const JSCore.StaticFunction[] js_funcs = {
            { "debug", debugJs, JSCore.PropertyAttribute.ReadOnly },
            { "warning", warningJs, JSCore.PropertyAttribute.ReadOnly },
            { "sendPropertyChange", sendPropertyChange, JSCore.PropertyAttribute.ReadOnly },
            { "seeked", onSeeked, JSCore.PropertyAttribute.ReadOnly },
            { null, null, 0 }
        };

        private const JSCore.ClassDefinition definition = {
            0,                          // version
            JSCore.ClassAttribute.None, // attribute
            API_NAME,                   // className
            null,                       // parentClass

            null,                       // static values
            js_funcs,                   // static functions

            null,                       // initialize
            null,                       // finalize

            null,                       // hasProperty
            null,                       // getProperty
            null,                       // setProperty
            null,                       // deleteProperty

            null,                       // getPropertyNames
            null,                       // callAsFunction
            null,                       // callAsConstructor
            null,                       // hasInstance
            null                        // convertToType
        };

        private static JSCore.Value debugJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            debug("Log from JS: %s", JsConverter.get_string(arguments[0], ctx));
            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value warningJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            warning("Warning from JS: %s", JsConverter.get_string(arguments[0], ctx));
            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value onSeeked (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            var v = JsConverter.get_variant(arguments[0], ctx);
            mSelf.Seeked((int64)v.get_double());

            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value sendPropertyChange (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            var v = JsConverter.get_variant(arguments[1], ctx);
	        HashTable<string, Variant> ht = (HashTable<string, Variant>) v;

            HashTable<PlayerProperties, Variant> changes = new HashTable<PlayerProperties, Variant>(direct_hash, direct_equal);
            PlayerProperties? prop = null;

            //Convert changes into enum types
	        ht.foreach ((key, val) => {
		        if(PlayerProperties.try_parse_name(key, out prop)) {
		            changes.insert(prop, val);
		        } else {
		            warning("Failed to parse javascript player property: %s", key);
		        }
	        });

        	if(changes.contains(PlayerProperties.ART_URL)) {
                cache_cover(changes);
	        } else {
                mSelf.send_property_change(changes);
	        }

            return new JSCore.Value.boolean(ctx, true);
        }

        private static void cache_cover(HashTable<PlayerProperties, Variant> changes) {

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

                mSelf.send_property_change(changes);
            });

           file_cache.cache_async(art_url, file_name);
        }

        [DBus (visible = false)]
        public void  SetContext(JSCore.GlobalContext context) {
            var apiClass = new JSCore.Class(definition);
            this.mContext.create_from_class(API_NAME, apiClass, context);

            mJsPlayer = mContext.get_property_object("Player");
        }

        public override PlayStatus PlaybackStatus {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("playbackStatus");
                    if(prop != null) {
                        return (PlayStatus) prop.get_double();
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
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canGoNext");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanGoPrevious {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canGoPrevious");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }


        public override bool CanPlay {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canPlay");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanPause {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canPause");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanSeek {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canSeek");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanControl {
            get {
                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("canControl");
                    if(prop != null) {
                        return prop.get_boolean();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool Shuffle {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsShuffle) {
                    Variant? prop = mJsPlayer.get_property_value("shuffle");
                    if(prop != null) {
                        ret = prop.get_boolean();
                    } else {
                        ret = false;
                    }
                }
                mShuffle = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsShuffle && this.Shuffle != value) {
                    mJsPlayer.call_function(PlayerAction.TOGGLE_SHUFFLE.to_string(), null);
                }
            }
        }

        public override bool Like {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsLike) {
                    Variant? prop = mJsPlayer.get_property_value("like");
                    if(prop != null) {
                        ret = prop.get_boolean();
                    } else {
                        ret = false;
                    }
                }
                mLike = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsLike && this.Like != value) {
                    Idle.add(() => {
                        mJsPlayer.call_function(PlayerAction.TOGGLE_LIKE.to_string(), null);
                        return false;
                    });
                }
            }
        }

        public override double Volume {
            get {
                double ret = 1;

                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("volume");
                    if(prop != null) {
                        ret = prop.get_double();
                    }
                }
                return ret;
            }
            set {
                if(mIntegrationReady) {
                    Idle.add(() => {
                        Variant[] args = new Variant[1];
                        args[0] = new Variant.double(value);
                        mJsPlayer.call_function(PlayerAction.VOLUME.to_string(), args);
                        return false;
                    });
                }
            }
        }

        public override int64 Position {
            get {
                int64 ret = 0;

                if(mIntegrationReady) {
                    Variant? prop = mJsPlayer.get_property_value("trackPosition");
                    if(prop != null) {
                        ret = (int64) prop.get_double();
                    }
                }
                return ret;
            }
            set {
                if(mIntegrationReady) {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.int64(value);
                    mJsPlayer.call_function(PlayerAction.TRACK_POSITION.to_string(), args);
                }
            }
        }

        public override bool CanShuffle {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsShuffle) {
                    Variant? prop = mJsPlayer.get_property_value("canShuffle");
                    if(prop != null) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override bool CanRepeat {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsRepeat) {
                    Variant? prop = mJsPlayer.get_property_value("canRepeat");
                    if(prop != null) {
                        ret = prop.get_boolean();
                    }
                }

                return ret;
            }
        }

        public override RepeatStatus Repeat {
            get {
                RepeatStatus repeat = RepeatStatus.NONE;
                if(mIntegrationReady && mService.SupportsRepeat) {
                    Variant? prop = mJsPlayer.get_property_value("repeat");
                    if(prop != null) {
                        repeat = (RepeatStatus) prop.get_double();
                    }
                }
                return repeat;
            }
            set {
                if(mIntegrationReady && mService.SupportsRepeat) {
                    Idle.add(() => {
                        Variant[] args = new Variant[1];
                        args[0] = new Variant.int32((int32)value);
                        mJsPlayer.call_function(PlayerAction.REPEAT.to_string(), args);
                        return false;
                    });
                }
            }
        }

        public override void Next() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mJsPlayer.call_function(PlayerAction.NEXT.to_string(), null);
                    return false;
                });
            }
        }

        public override void Previous() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mJsPlayer.call_function(PlayerAction.PREVIOUS.to_string(), null);
                    return false;
                });
            }
        }

        public override void Pause() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mJsPlayer.call_function(PlayerAction.PAUSE.to_string(), null);
                    return false;
                });
            }
        }

        public override void Stop() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mJsPlayer.call_function(PlayerAction.STOP.to_string(), null);
                    return false;
                });
            }
        }

        public override void Play() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mJsPlayer.call_function(PlayerAction.PLAY.to_string(), null);
                    return false;
                });
            }
        }

        public override void Search(string term) {

            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string(term);
                    mJsPlayer.call_function(BrowserAction.SEARCH.to_string(), args);
                    return false;
                });
            }
        }

        public override void Show(string type, string id) {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[2];
                    args[0] = new Variant.string(type);
                    args[1] = new Variant.string(id);
                    mJsPlayer.call_function(BrowserAction.SHOW.to_string(), args);
                    return false;
                });
            }
        }

        private void InjectApi() {
            if(mService.ApiVersion != REQUIRED_API_VERSION) {
                mIntegrationReady = false;
                warning("Service %s is not supporting required API Version %i." +
                    " Integration not loaded.", mService.Name, REQUIRED_API_VERSION);
            } else if(mService.IntegratesService) {
                string serviceFile;
                string baseApi;
                string path;

                try {
                    path = Directory.GetServiceDir() + "api.js";
                    FileUtils.get_contents(path, out baseApi);

                    path = mService.IntegrationFilePath;
                    FileUtils.get_contents(path, out serviceFile);

                    debug("Injecting %s: %s", mService.Ident, path);

                    mContext.EvaluateScript(baseApi, path, 1);
                    mContext.EvaluateScript(serviceFile, path, 1);
                    mIntegrationReady = true;

                    mContext.call_function("init", null);

                } catch(FileError e) {
                    mIntegrationReady = false;

                    critical("Could not load content of service file (%s). " +
                            "Integration disabled. (%s)", path, e.message);
                }

            } else {
                mIntegrationReady = false;
                debug("No integration supported for service %s.", mService.Name);
            }
        }

        private void OnContextChanged() {
            this.InjectApi();
        }
    }
}

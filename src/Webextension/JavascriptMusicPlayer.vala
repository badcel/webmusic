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

    [DBus(name = "org.WebMusic.Webextension.Player")]
    private class JavascriptMusicPlayer : WebMusicPlayer {

        private const int REQUIRED_API_VERSION = 1;
        private static const string API_NAME = "WebMusicApi";

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
        }

        ~JavascriptMusicPlayer() {
            StopCheckDom();
        }


        private static const JSCore.StaticFunction[] js_funcs = {
            { "debug", debugJs, JSCore.PropertyAttribute.ReadOnly },
            { "warning", warningJs, JSCore.PropertyAttribute.ReadOnly },
            { "sendPropertyChange", sendPropertyChange, JSCore.PropertyAttribute.ReadOnly },
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

        private static JSCore.Value sendPropertyChange (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            GLib.Variant? val = null;
            string? key = null;
            var v = JsConverter.get_variant(arguments[1], ctx);

            return new JSCore.Value.boolean(ctx, true);
        }


        [DBus (visible = false)]
        public void  SetContext(JSCore.GlobalContext context) {
            var apiClass = new JSCore.Class(definition);
            this.mContext.create_from_class(API_NAME, apiClass, context);

            mJsPlayer = mContext.get_property_object("Player");
        }

        protected override string GetArtist() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("artist");
                if(prop != null) {
                    return prop.get_string(null);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetTrack()  {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("track");
                if(prop != null) {
                    return prop.get_string(null);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetAlbum() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("album");
                if(prop != null) {
                    return prop.get_string(null);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override int64 GetTrackLength() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("trackLength");
                if(prop != null) {
                    return (int64) prop.get_double();
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        }

        protected override string GetArtUrl() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("artUrl");
                if(prop != null) {
                    return prop.get_string(null);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetUrl() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("url");
                if(prop != null) {
                    return prop.get_string();
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override bool GetReady() {
            if(mIntegrationReady) {
                Variant? prop = mJsPlayer.get_property_value("ready");
                if(prop != null) {
                    return prop.get_boolean();
                } else {
                    return false;
                }
            } else {
                return false;
            }
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
                if(mIntegrationReady && mService.SupportsShuffle && mShuffle != value) {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("toggle-shuffle");
                    mContext.call_function("ActivateAction", args);
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
                if(mIntegrationReady && mService.SupportsLike && mLike != value) {
                    Idle.add(() => {
                        Variant[] args = new Variant[1];
                        args[0] = new Variant.string("toggle-like");
                        mContext.call_function("ActivateAction", args);
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
                        Variant[] args = new Variant[2];
                        args[0] = new Variant.string("volume");
                        args[1] = new Variant.double(value);
                        mContext.call_function("ActivateAction", args);
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
                    Variant[] args = new Variant[2];
                    args[0] = new Variant.string("track-position");
                    args[1] = new Variant.int64(value);
                    mContext.call_function("ActivateAction", args);
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
                        Variant[] args = new Variant[2];
                        args[0] = new Variant.string("repeat");
                        args[1] = new Variant.int32((int32)value);
                        mContext.call_function("ActivateAction", args);
                        return false;
                    });
                }
            }
        }

        public override void Next() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("next");
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Previous() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("previous");
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Pause() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("pause");
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Stop() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("stop");
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Play() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("play");
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Search(string term) {

            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[2];
                    args[0] = new Variant.string("search");
                    args[1] = new Variant.string(term);
                    mContext.call_function("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Show(string type, string id) {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[3];
                    args[0] = new Variant.string("show");
                    args[1] = new Variant.string(type);
                    args[2] = new Variant.string(id);
                    mContext.call_function("ActivateAction", args);
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

                    StartCheckDom();

                } catch(FileError e) {
                    mIntegrationReady = false;
                    StopCheckDom();
                    critical("Could not load content of service file (%s). " +
                            "Integration disabled. (%s)", path, e.message);
                }

            } else {
                mIntegrationReady = false;
                debug("No integration supported for service %s.", mService.Name);
                StopCheckDom();
            }

            if(!mIntegrationReady) {
                Reset();
            }
        }

        private void OnContextChanged() {
            this.InjectApi();
        }
    }
}

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

namespace WebMusic.Webextension {

    [DBus(name = "org.WebMusic.Webextension.Player")]
    private class JavascriptMusicPlayer : WebMusicPlayer {

       private const int REQUIRED_API_VERSION = 1;

        private JavascriptContext mContext;
        private Service mService;
        private bool mIntegrationReady = false;
        private bool mShuffle = false;
        private bool mLike = false;

        public JavascriptMusicPlayer(Service service, JavascriptContext context) {
            mService = service;

            mContext = context;
            mContext.ContextChanged.connect(OnContextChanged);

            this.InjectApi();
        }

        ~JavascriptMusicPlayer() {
            StopCheckDom();
        }

        protected override string GetArtist() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("artist", out prop)) {
                    return mContext.GetUTF8String(prop);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetTrack()  {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("track", out prop)) {
                    return mContext.GetUTF8String(prop);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetAlbum() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("album", out prop)) {
                    return mContext.GetUTF8String(prop);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override int64 GetTrackLength() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("trackLength", out prop)) {
                    return mContext.GetInteger(prop);
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        }

        protected override string GetArtUrl() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("artUrl", out prop)) {
                    return mContext.GetUTF8String(prop);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override string GetUrl() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("url", out prop)) {
                    return mContext.GetUTF8String(prop);
                } else {
                    return "";
                }
            } else {
                return "";
            }
        }

        protected override bool GetReady() {
            if(mIntegrationReady) {
                JSCore.Value prop;
                if(mContext.get_property("ready", out prop)) {
                    return mContext.GetBoolean(prop);
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
                    JSCore.Value prop;
                    if(mContext.get_property("playbackStatus", out prop)) {
                        return (PlayStatus) mContext.GetInteger(prop);
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
                    JSCore.Value prop;
                    if(mContext.get_property("canGoNext", out prop)) {
                        return mContext.GetBoolean(prop);
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
                    JSCore.Value prop;
                    if(mContext.get_property("canGoPrevious", out prop)) {
                        return mContext.GetBoolean(prop);
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }


        public override bool CanPlay    {
            get {
                if(mIntegrationReady) {
                    JSCore.Value prop;
                    if(mContext.get_property("canPlay", out prop)) {
                        return mContext.GetBoolean(prop);
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanPause   {
            get {
                if(mIntegrationReady) {
                    JSCore.Value prop;
                    if(mContext.get_property("canPause", out prop)) {
                        return mContext.GetBoolean(prop);
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        }

        public override bool CanSeek    {
            get {
                if(mIntegrationReady) {
                    JSCore.Value prop;
                    if(mContext.get_property("canSeek", out prop)) {
                        return mContext.GetBoolean(prop);
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
                    JSCore.Value prop;
                    if(mContext.get_property("canControl", out prop)) {
                        return mContext.GetBoolean(prop);
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
                    JSCore.Value prop;
                    if(mContext.get_property("shuffle", out prop)) {
                        ret = mContext.GetBoolean(prop);
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
                    mContext.CallFunction("ActivateAction", args);
                }
            }
        }

        public override bool Like {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsLike) {
                    JSCore.Value prop;
                    if(mContext.get_property("like", out prop)) {
                        ret = mContext.GetBoolean(prop);
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
                        mContext.CallFunction("ActivateAction", args);
                        return false;
                    });
                }
            }
        }

        public override double Volume {
            get {
                double ret = 1;

                if(mIntegrationReady) {
                    JSCore.Value prop;
                    if(mContext.get_property("volume", out prop)) {
                        ret = mContext.GetDouble(prop);
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
                        mContext.CallFunction("ActivateAction", args);
                        return false;
                    });
                }
            }
        }

        public override int64 Position {
            get {
                int64 ret = 0;

                if(mIntegrationReady) {
                    JSCore.Value prop;
                    if(mContext.get_property("trackPosition", out prop)) {
                        ret = (int64) mContext.GetDouble(prop);
                    }
                }
                return ret;
            }
            set {
                if(mIntegrationReady) {
                    Variant[] args = new Variant[2];
                    args[0] = new Variant.string("track-position");
                    args[1] = new Variant.int64(value);
                    mContext.CallFunction("ActivateAction", args);
                }
            }
        }

        public override bool CanShuffle {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsShuffle) {
                    JSCore.Value prop;
                    if(mContext.get_property("canShuffle", out prop)) {
                        ret = mContext.GetBoolean(prop);
                    }
                }

                return ret;
            }
        }

        public override bool CanRepeat {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsRepeat) {
                    JSCore.Value prop;
                    if(mContext.get_property("canRepeat", out prop)) {
                        ret = mContext.GetBoolean(prop);
                    }
                }

                return ret;
            }
        }

        public override RepeatStatus Repeat {
            get {
                RepeatStatus repeat = RepeatStatus.NONE;
                if(mIntegrationReady && mService.SupportsRepeat) {
                    JSCore.Value prop;
                    if(mContext.get_property("repeat", out prop)) {
                        repeat = (RepeatStatus) mContext.GetInteger(prop);
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
                        mContext.CallFunction("ActivateAction", args);
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
                    mContext.CallFunction("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Previous() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("previous");
                    mContext.CallFunction("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Pause() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("pause");
                    mContext.CallFunction("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Stop() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("stop");
                    mContext.CallFunction("ActivateAction", args);
                    return false;
                });
            }
        }

        public override void Play() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    Variant[] args = new Variant[1];
                    args[0] = new Variant.string("play");
                    mContext.CallFunction("ActivateAction", args);
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
                    mContext.CallFunction("ActivateAction", args);
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
                    mContext.CallFunction("ActivateAction", args);
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

                    mContext.CallFunction("init", null);

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

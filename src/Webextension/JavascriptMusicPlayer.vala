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
                return mContext.CallFunctionAsString("GetArtist", null);
            } else {
                return "";
            }
        }

        protected override string GetTrack()  {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsString("GetTrack", null);
            } else {
                return "";
            }
        }

        protected override string GetAlbum() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsString("GetAlbum", null);
            } else {
                return "";
            }
        }

        protected override int64 GetTrackLength() {
            if(mIntegrationReady && mService.SupportsSeek) {
                return mContext.CallFunctionAsInteger("GetTrackLength", null);
            } else {
                return 0;
            }
        }

        protected override string GetArtUrl() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsString("GetArtUrl", null);
            } else {
                return "";
            }
        }

        protected override bool GetReady() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsBoolean("GetReady", null);
            } else {
                return false;
            }
        }

        public override PlayStatus PlaybackStatus {
            get {
                if(mIntegrationReady) {
                    return (PlayStatus) mContext.CallFunctionAsInteger("GetPlaybackStatus", null);
                } else {
                    return PlayStatus.STOP;
                }
            }
        }

        public override bool CanGoNext {
            get {
                if(mIntegrationReady) {
                    return mContext.CallFunctionAsBoolean("GetCanGoNext", null);
                } else {
                    return false;
                }
            }
        }

        public override bool CanGoPrevious {
            get {
                if(mIntegrationReady) {
                    return mContext.CallFunctionAsBoolean("GetCanGoPrevious", null);
                } else {
                    return false;
                }
            }
        }


        public override bool CanPlay    { get { return mIntegrationReady; } }
        public override bool CanPause   { get { return mService.SupportsPause; } }
        public override bool CanSeek    { get { return mService.SupportsSeek; } }
        public override bool CanControl { get { return mIntegrationReady; } }

        public override bool Shuffle {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsShuffle) {
                    ret = mContext.CallFunctionAsBoolean("GetShuffle", null);
                }
                mShuffle = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsShuffle && mShuffle != value) {
                    mContext.CallFunction("ToggleShuffle", null);
                }
            }
        }

        public override bool Like {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsLike) {
                    ret = mContext.CallFunctionAsBoolean("GetLike", null);
                }
                mLike = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsLike && mLike != value) {
                    Idle.add(() => {
                        mContext.CallFunction("ToggleLike", null);
                        return false;
                    });
                }
            }
        }

        public override double Volume {
            get {
                double ret = 1;

                if(mIntegrationReady && mService.SupportsVolume) {
                    ret = mContext.CallFunctionAsDouble("GetVolume", null);
                }
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsVolume) {
                    Idle.add(() => {
                        Variant v = new Variant.double(value);
                        mContext.CallFunction("SetVolume", v);
                        return false;
                    });
                }
            }
        }

        public override int64 Position {
            get {
                int64 ret = 0;

                if(mIntegrationReady && mService.SupportsSeek) {
                    ret = (int64) mContext.CallFunctionAsDouble("GetTrackPosition", null);
                }
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsSeek) {
                    Variant v = new Variant.int64(value);
                    mContext.CallFunction("SetTrackPosition", v);
                }
            }
        }

        public override bool CanShuffle {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsShuffle) {
                    ret = mContext.CallFunctionAsBoolean("CanShuffle", null);
                }

                return ret;
            }
        }

        public override bool CanRepeat {
            get {
                bool ret = false;

                if(mIntegrationReady && mService.SupportsRepeat) {
                    ret = mContext.CallFunctionAsBoolean("CanRepeat", null);
                }

                return ret;
            }
        }

        public override RepeatStatus Repeat {
            get {
                RepeatStatus repeat = RepeatStatus.NONE;
                if(mIntegrationReady && mService.SupportsRepeat) {
                    repeat = (RepeatStatus)mContext.CallFunctionAsInteger("GetRepeat", null);
                }
                return repeat;
            }
            set {
                if(mIntegrationReady && mService.SupportsRepeat) {
                    Idle.add(() => {
                        Variant v = new Variant.int32((int32)value);
                        mContext.CallFunction("SetRepeat", v);
                        return false;
                    });
                }
            }
        }

        public override void Next() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Next", null);
                    return false;
                });
            }
        }

        public override void Previous() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Previous", null);
                    return false;
                });
            }
        }

        public override void Pause() {
            if(!mService.SupportsPause) {
                Stop();
            } else {
                if(mIntegrationReady) {
                    Idle.add(() => {
                        mContext.CallFunction("Pause", null);
                        return false;
                    });
                }
            }
        }

        public override void Stop() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Stop", null);
                    return false;
                });
            }
        }

        public override void Play() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Play", null);
                    base.Play();
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
                string path = mService.IntegrationFilePath;

                try {
                    FileUtils.get_contents(path, out serviceFile);

                    debug("Injecting %s: %s", mService.Ident, path);

                    mContext.EvaluateScript(serviceFile, path, 1);
                    mIntegrationReady = true;
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

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

using WebMusic.Lib;

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
                return mContext.CallFunctionAsString("GetArtist");
            } else {
                return "";
            }
        }
        
        protected override string GetTrack()  {
            if(mIntegrationReady) {      
                return mContext.CallFunctionAsString("GetTrack");
            } else {
                return "";
            }
        }
        
        protected override string GetAlbum() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsString("GetAlbum");
            } else {
                return "";
            }
        }
        
        protected override string GetArtUrl() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsString("GetArtUrl");
            } else {
                return "";
            }
        }
        
        protected override bool GetReady() {
            if(mIntegrationReady) {
                return mContext.CallFunctionAsBoolean("GetReady");
            } else {
                return false;
            }
        }
        
        public override PlayStatus PlaybackStatus {
            get { 
                if(mIntegrationReady) {
                    return (PlayStatus) mContext.CallFunctionAsInteger("GetPlaybackStatus");
                } else {
                    return PlayStatus.STOP;
                }
            }
        }
        
        public override bool CanGoNext {
            get { 
                if(mIntegrationReady) {
                    return mContext.CallFunctionAsBoolean("GetCanGoNext");
                } else {
                    return false;
                }
            }
        }
        
        public override bool CanGoPrevious {
            get { 
                if(mIntegrationReady) {
                    return mContext.CallFunctionAsBoolean("GetCanGoPrevious");
                } else {
                    return false;
                }
            }
        }
        
        
        public override bool CanPlay    { get { return mIntegrationReady;  } }
        public override bool CanPause   { get { return mIntegrationReady;  } }
        public override bool CanSeek    { get { return false; } }   
        public override bool CanControl { get { return mIntegrationReady;  } }
        
        public override bool Shuffle {
            get {
                bool ret = false;
                
                if(mIntegrationReady && mService.SupportsShuffle) {
                    ret = mContext.CallFunctionAsBoolean("GetShuffle");
                }
                mShuffle = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsShuffle && mShuffle != value) {
                    mContext.CallFunction("ToggleShuffle");
                }
            }
        }
        
        public override bool Like {
            get {
                bool ret = false;
                
                if(mIntegrationReady && mService.SupportsLike) {
                    ret = mContext.CallFunctionAsBoolean("GetLike");
                }
                mLike = ret;
                return ret;
            }
            set {
                if(mIntegrationReady && mService.SupportsLike && mLike != value) {
                    mContext.CallFunction("ToggleLike");
                }
            }
        }
        
        public override bool CanShuffle {
            get {
                bool ret = false;
                
                if(mIntegrationReady && mService.SupportsShuffle) {
                    ret = mContext.CallFunctionAsBoolean("CanShuffle");
                }
                
                return ret;
            }
        }
        
        public override Repeat LoopStatus {
            get {
                Repeat loopStatus = Repeat.NONE;
                if(mIntegrationReady && mService.SupportsLoopStatus) {
                    loopStatus = (Repeat)mContext.CallFunctionAsInteger("GetLoopStatus");
                }
                return loopStatus;
            }
            set { /*TODO, JavascriptContext misses support for parameters */ }
        }
        
        public override void Next() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Next");
                    return false;
                });
            }
        }
        
        public override void Previous() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Previous");
                    return false;
                });
            }
        }
        
        public override void Pause() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Pause");
                    return false;
                });
            }
        }
        
        public override void Stop() {
            Pause();
        }
        
        public override void Play() {
            if(mIntegrationReady) {
                Idle.add(() => {
                    mContext.CallFunction("Play");
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
                } catch(FileError e) {
                    StopCheckDom();
                    critical("Could not load content of service file (%s). " +
                            "Integration disabled. (%s)", path, e.message);
                }
                
                debug("Injecting %s: %s", mService.Ident, path);
                
                //TODO Check for file errors        
                mContext.EvaluateScript(serviceFile, path, 1);
                mIntegrationReady = true;
                StartCheckDom();
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

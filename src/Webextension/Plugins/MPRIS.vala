/*
 *  Copyright (C) 2010 Andreas Obergrusberger
 *  Copyright (C) 2010 - 2012 Jörn Magens
 *  Copyright (C) 2014, 2015 Marcel Tiede
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Author:
 *  Andreas Obergrusberger
 *  Jörn Magens
 *  Marcel Tiede
 */

using LibWebMusic;
using WebMusic.Webextension;

namespace WebMusic.Webextension.Plugins {

    private errordomain MprisError {
        COULD_NOT_ACQUIRE_BUS
    }

    private class Mpris : GLib.Object, IPlugin {

        private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";

        private uint mOwnerId;
        private uint mRootId;
        private uint mPlayerId;
        private bool mEnable;

        private Player mPlayer = null;
        private Service mService = null;
        private MprisRoot mRoot = null;
        private MprisPlayer mMprisPlayer = null;

        private DBusConnection mConnection;

        public bool Enable {
            get { return mEnable; }
            set {
                mEnable = value;

                if(value) {
                    OwnBus();
                } else {
                    ReleaseBus();
                }
            }
        }

        public Mpris(BrowserDBus browser, Service service) {
            mService = service;
            mService.ServiceLoaded.connect(OnServiceChanged);

            mRoot = new MprisRoot(browser, service);
        }

        ~Mpris() {
            ReleaseBus();
        }

        public bool RegisterPlayer(Player player){

            mPlayer = player;

            //TODO Connect if dbus name aquired and disconnect if dbus name lost
            mPlayer.PropertiesChanged.connect(OnPropertiesChanged);

            //TODO Check what to do if player gets inactive (signal if no integration available)

            mMprisPlayer = new MprisPlayer(mPlayer);

            return true;
        }

        private bool OwnBus() {
            mOwnerId = Bus.own_name(BusType.SESSION,
                                        "org.mpris.MediaPlayer2.WebMusic.instance1",
                                         GLib.BusNameOwnerFlags.NONE,
                                         OnBusAcquired,
                                         OnNameAcquired,
                                         OnNameLost);
            return mOwnerId != 0;
        }

        private void ReleaseBus() {

            if(mRootId != 0) {
                mConnection.unregister_object(mRootId);
            }

            if(mPlayerId != 0) {
                mConnection.unregister_object(mPlayerId);
            }

            if(mOwnerId != 0) {
                Bus.unown_name(mOwnerId);
            }

            mOwnerId = 0;
            mRootId = 0;
            mPlayerId = 0;
        }

        private void OnBusAcquired(DBusConnection connection, string name) {
            this.mConnection = connection;
            try {
                debug("DBus: Bus %s acquired\n", name);
                mRootId = connection.register_object("/org/mpris/MediaPlayer2", mRoot);
                mPlayerId = connection.register_object("/org/mpris/MediaPlayer2", mMprisPlayer);
            }
            catch(IOError e) {
                warning("Could not register dbus object (%s).", e.message);
            }
        }

        private void OnNameAcquired(DBusConnection connection, string name) {
            debug("DBus: Name %s acquired.", name);
        }

        private void OnNameLost(DBusConnection connection, string name) {
            debug("DBus: Name %s lost.", name);
        }

        private void SendPropertyChange(Variant dict) {

            var invalidated_builder = new VariantBuilder(new VariantType("as"));

            Variant[] arg_tuple = {
                new Variant("s", INTERFACE_NAME),
                dict,
                invalidated_builder.end()
            };
            Variant args = new Variant.tuple(arg_tuple);

            try {
                this.mConnection.emit_signal(null,
                                 "/org/mpris/MediaPlayer2",
                                 "org.freedesktop.DBus.Properties",
                                 "PropertiesChanged",
                                 args
                );
            }
            catch(Error e) {
                critical("Error emmitting PropertiesChanged DBus signal. (%s)", e.message);
            }

        }

        private void OnServiceChanged() {
            if(!mService.IntegratesService) {
               this.reset_data();
            }
        }

        private void OnPropertiesChanged(HashTable<PlayerProperties,Variant> dict) {

            if(!this.Enable || mConnection.closed)
                return;

            HashTable<string, Variant> data = new HashTable<string, Variant>(str_hash, str_equal);
            bool has_metadata = false;

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
                        var playstatus = (PlayStatus) val.get_double();
                        data.insert("PlaybackStatus", playstatus.to_string());
                        break;
                    case PlayerProperties.SHUFFLE:
                        data.insert("Shuffle", val);
                        break;
                    case PlayerProperties.REPEAT:
                        var repeat = (RepeatStatus) val.get_double();
                        data.insert("LoopStatus", repeat.to_string());
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
                        has_metadata = true;
                        break;
                }
	        });

            if(has_metadata) {
                mMprisPlayer.set_metadata(dict);
                data.insert("Metadata", mMprisPlayer.Metadata);
            }

            this.SendPropertyChange(data);
        }

        private void reset_data() {

            HashTable<string, Variant> data = new HashTable<string, Variant>(str_hash, str_equal);

            data.insert("CanControl", new Variant.boolean(false));
            data.insert("CanPlay", new Variant.boolean(false));
            data.insert("CanPause", new Variant.boolean(false));
            data.insert("CanSeek", new Variant.boolean(false));
            data.insert("CanGoNext", new Variant.boolean(false));
            data.insert("CanGoPrevious", new Variant.boolean(false));
            data.insert("CanShuffle", new Variant.boolean(false));
            data.insert("CanRepeat", new Variant.boolean(false));
            data.insert("PlaybackStatus", PlayStatus.STOP.to_string());
            data.insert("Shuffle", new Variant.boolean(false));
            data.insert("LoopStatus", RepeatStatus.NONE.to_string());
            data.insert("Volume", new Variant.double(0.0));

            mMprisPlayer.reset_metadata();
            data.insert("Metadata", mMprisPlayer.Metadata);

            this.SendPropertyChange(data);

        }
    }

    [DBus(name = "org.mpris.MediaPlayer2")]
    private class MprisRoot : GLib.Object {

        public bool CanQuit          { get { return true;  } }
        public bool CanRaise         { get { return true;  } }
        public bool HasTrackList     { get { return false; } }
        public bool CanSetFullscreen { get { return true; } }

        private BrowserDBus mBrowser;
        private Service     mService;

        public MprisRoot(BrowserDBus browser, Service service) {
            mBrowser = browser;
            mService = service;
        }

        //TODO Support fullscreen
        public bool Fullscreen {
            get { return false; }
            set { }
        }

        public string DesktopEntry {
            owned get {
                return "webmusic";
            }
        }

        public string Identity {
            owned get { return _("WebMusic"); }
        }

        public string[] SupportedUriSchemes {
            owned get { return {}; }
        }

        public string[] SupportedMimeTypes {
            owned get {return {}; }
        }

        public void Quit() {
            try {
                mBrowser.Quit();
            } catch(GLib.IOError e) {
                warning("Could not quit application due to a DBus error. (%s)", e.message);
            }
        }

        public void Raise() {
            try {
                mBrowser.Raise();
            } catch(GLib.IOError e) {
                warning("Could not raise application due to a DBus error. (%s)", e.message);
            }
        }
    }

    [DBus(name = "org.mpris.MediaPlayer2.Player")]
    private class MprisPlayer : GLib.Object {

        public signal void Seeked(int64 position);

        private Player mPlayer;

        public MprisPlayer(Player player) {
            mPlayer = player;
            mPlayer.Seeked.connect(OnSeeked);
        }

        public string PlaybackStatus
        {
            owned get { return mPlayer.PlaybackStatus.to_string(); }
        }

        public string LoopStatus {
            owned get { return mPlayer.Repeat.to_string(); }
            set {
                RepeatStatus status;

                if(!RepeatStatus.try_parse_name(value, out status)) {
                    warning("Unknown loopstatus string '%s'", value);
                }
                mPlayer.Repeat = status;

            }
        }

        public double Rate {
            get { return 1.0; }
            set {  }
        }

        public bool Shuffle {
            get { return mPlayer.Shuffle; }
            set { mPlayer.Shuffle = value; }
        }

        public double Volume {
            get { return mPlayer.Volume; }
            set { mPlayer.Volume = value; }
        }

        public int64 Position {
            get { return mPlayer.Position; }
        }

        public double MinimumRate   { get { return 1.0; } }
        public double MaximumRate   { get { return 1.0; } }

        private HashTable<string,Variant> _metadata = new HashTable<string,Variant>(str_hash, str_equal);
        public HashTable<string,Variant> Metadata { //a{sv}
            owned get {
                Variant variant = "/";
                _metadata.insert("mpris:trackid", variant); //dummy
                return _metadata;
            }
        }

        public bool   CanGoNext     { get { return mPlayer.CanGoNext;     } }
        public bool   CanGoPrevious { get { return mPlayer.CanGoPrevious; } }
        public bool   CanPlay       { get { return mPlayer.CanPlay;       } }
        public bool   CanPause      { get { return mPlayer.CanPause;      } }
        public bool   CanSeek       { get { return mPlayer.CanSeek;       } }
        public bool   CanControl    { get { return mPlayer.CanControl;    } }

        public void Next() {
            mPlayer.Next();
        }

        public void Previous() {
            mPlayer.Previous();
        }

        public void Pause() {
            mPlayer.Pause();
        }

        public void Stop() {
            mPlayer.Stop();
        }

        public void Play() {
            mPlayer.Play();
        }

        public void Seek(int64 offset) {
            //TODO: Implement
        }

        public void SetPosition(ObjectPath TrackId, int64 Position) {
            mPlayer.Position = Position;
            this.Seeked(Position);
        }

        public void PlayPause() {
            if(mPlayer.PlaybackStatus != PlayStatus.PLAY) {
                this.Play();
            } else {
                this.Pause();
            }
        }

        [DBus (visible = false)]
        public void set_metadata(HashTable<PlayerProperties,Variant> dict) {

            _metadata = new HashTable<string,Variant>(str_hash, str_equal);

            dict.foreach ((key, val) => {
                switch(key) {
                    case PlayerProperties.URL:
                        _metadata.insert("xesam:url", val);
                        break;
                    case PlayerProperties.ARTIST:
                        _metadata.insert("xesam:artist", val);
                        break;
                    case PlayerProperties.TRACK:
                        _metadata.insert("xesam:title", val);
                        break;
                    case PlayerProperties.ALBUM:
                        _metadata.insert("xesam:album", val);
                        break;
                    case PlayerProperties.ART_FILE_LOCAL:
                        _metadata.insert("mpris:artUrl", val);
                        break;
                    case PlayerProperties.TRACK_LENGTH:
                        int64 length = (int64)val.get_double();
                        _metadata.insert("mpris:length", new Variant.int64(length));
                        break;
                }
	        });
        }

        [DBus (visible = false)]
        public void reset_metadata() {

            _metadata = new HashTable<string,Variant>(str_hash, str_equal);

            _metadata.insert("xesam:url", "");
            _metadata.insert("xesam:artist", "");
            _metadata.insert("xesam:title", "");
            _metadata.insert("xesam:album", "");
            _metadata.insert("mpris:artUrl", "");
            _metadata.insert("mpris:length", new Variant.int64(0));
        }

        private void OnSeeked(int64 position) {
            this.Seeked(position); // Forward signal
        }
    }

}


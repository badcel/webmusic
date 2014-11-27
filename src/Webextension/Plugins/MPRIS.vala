/*
 *  Copyright (C) 2010 Andreas Obergrusberger
 *  Copyright (C) 2010 - 2012 Jörn Magens
 *  Copyright (C) 2014 Marcel Tiede
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

using WebMusic.Lib;
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

        private unowned DBusConnection mConnection;

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
            mPlayer.MetadataChanged.connect(OnMetadataChanged);
            mPlayer.PlayercontrolChanged.connect(OnPlayercontrolChanged);

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
                mRootId = connection.register_object("/org/mpris/MediaPlayer2", mRoot);
                mPlayerId = connection.register_object("/org/mpris/MediaPlayer2", mMprisPlayer);
            }
            catch(IOError e) {
                stdout.printf("%s\n", e.message);
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
                OnMetadataChanged("", "", "", "");
                OnPlayercontrolChanged(false, false, false, false, false, false,
                                        PlayStatus.STOP, Repeat.NONE);
            }
        }

        private void OnMetadataChanged(string artist, string track, string album, string artUrl) {

            if(!this.Enable || mConnection.closed)
                return;

            mMprisPlayer.SetMetadata(artist, track, album, artUrl);
            Variant variant = mMprisPlayer.Metadata;
            var builder = new VariantBuilder(VariantType.DICTIONARY);
            builder.add("{sv}", "Metadata", variant);

            this.SendPropertyChange(builder.end());
        }

        private void OnPlayercontrolChanged(bool canGoNext, bool canGoPrev, bool canShuffle,
                        bool canRepeat, bool shuffle, bool like, PlayStatus playStatus, Repeat loopStatus) {

            if(!this.Enable || mConnection.closed)
                return;

            HashTable<string,Variant> dict = new HashTable<string,Variant>(str_hash, str_equal);
            dict.insert("CanGoNext",      new Variant.boolean(canGoNext));
            dict.insert("CanGoPrevious",  new Variant.boolean(canGoPrev));
            dict.insert("Shuffle",        new Variant.boolean(shuffle));
            dict.insert("PlaybackStatus", new Variant.string(playStatus.to_string()));
            dict.insert("LoopStatus", new Variant.string(loopStatus.to_string()));

            this.SendPropertyChange(dict);
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

        //TODO Send property change if identity changes!
        public string Identity {
            owned get { return _("WebMusic") + " (%s)".printf(mService.Name); }
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

        private Player mPlayer;

        public MprisPlayer(Player player) {
            mPlayer = player;
        }

        public string PlaybackStatus
        {
            owned get { return mPlayer.PlaybackStatus.to_string(); }
        }

        public string LoopStatus {
            owned get { return mPlayer.LoopStatus.to_string(); }
            set {

                switch(value) {
                    case "None":
                        mPlayer.LoopStatus = Repeat.NONE;
                        break;
                    case "Track":
                        mPlayer.LoopStatus = Repeat.TRACK;
                        break;
                    case "Playlist":
                        mPlayer.LoopStatus = Repeat.PLAYLIST;
                        break;
                    default:
                        stdout.printf("Unknown Loopstatus string %s", value);
                        mPlayer.LoopStatus = Repeat.NONE;
                        break;
                }

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
            get { return 1; }
            set {  }
        }

        public int64 Position {
            get { return 1; }
            set {  }
        }

        public double MinimumRate   { get { return 1.0;   } }
        public double MaximumRate   { get { return 1.0;   } }

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

        public signal void Seeked(int64 Position);

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

        public void Seek(int64 offset){}
        public void SetPosition(ObjectPath TrackId, int64 Position){}

        public void PlayPause() {
            if(mPlayer.PlaybackStatus != PlayStatus.PLAY) {
                this.Play();
            } else {
                this.Pause();
            }
        }

        public void SetMetadata(string artist, string track, string album, string artUrl) {

            _metadata = new HashTable<string,Variant>(str_hash, str_equal);
            _metadata.insert("xesam:title",  new Variant.string(track));
            _metadata.insert("mpris:artUrl", new Variant.string(artUrl));

            if(artist.length > 0) {
                _metadata.insert("xesam:artist", new Variant.string(artist));
            }

            if(album.length > 0) {
                _metadata.insert("xesam:album", new Variant.string(album));
            }
        }
    }

}


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

namespace WebMusic.Browser.Plugins {

    private errordomain MprisError {
        COULD_NOT_ACQUIRE_BUS
    }

    private class Mpris : GLib.Object, IPlugin {

        private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";

        private uint owner_id;
        private uint root_id;
        private uint player_id;
        private uint playlist_id;
        private bool enable;

        private Player player;
        private PlaylistApi playlist;
        private Service service;
        private MprisRoot mpris_root;
        private MprisPlayer mpris_player;
        private MprisPlaylists mpris_playlists;

        private DBusConnection dbus_connection;

        public bool Enable {
            get { return enable; }
            set {
                enable = value;

                if(value) {
                    own_bus();
                } else {
                    release_bus();
                }
            }
        }

        public Mpris(WebMusic webmusic, Service s) {
            service = s;
            service.ServiceLoaded.connect(OnServiceChanged);

            player = Player.get_instance();
            player.PropertiesChanged.connect(on_player_properties_changed);
            player.ApiReady.connect(on_api_ready); //ApiReay signal is the same for player / playlist

            playlist = PlaylistApi.get_instance();
            playlist.PropertiesChanged.connect(on_playlist_properties_changed);

            mpris_root = new MprisRoot(webmusic, service);
            mpris_player = new MprisPlayer(player);
            mpris_playlists = new MprisPlaylists(playlist);
        }

        ~Mpris() {
            release_bus();
        }

        private void own_bus() {

            if(player.api_ready && owner_id == 0) {
                //api is ready and bus unowned
                owner_id = Bus.own_name(BusType.SESSION,
                                            "org.mpris.MediaPlayer2.WebMusic.instance1",
                                             GLib.BusNameOwnerFlags.NONE,
                                             on_bus_acquired,
                                             on_name_acquired,
                                             on_name_lost);
            }
        }

        private void release_bus() {

            if(player_id != 0) {
                dbus_connection.unregister_object(player_id);
                player_id = 0;
            }

            if(playlist_id != 0) {
                dbus_connection.unregister_object(playlist_id);
                playlist_id = 0;
            }

            if(root_id != 0) {
                dbus_connection.unregister_object(root_id);
                root_id = 0;
            }

            if(owner_id != 0) {
                Bus.unown_name(owner_id);
                owner_id  = 0;
            }
        }

        private void on_api_ready(bool ready) {
            if(this.Enable) {
                this.own_bus();
            }
        }

        private void register_objects() {

            if(!this.Enable || this.owner_id == 0 || !player.api_ready) {
                return;
            }

            try {
                root_id = dbus_connection.register_object("/org/mpris/MediaPlayer2", mpris_root);
                player_id = dbus_connection.register_object("/org/mpris/MediaPlayer2", mpris_player);

                if(service.SupportsPlaylists) {
                    playlist_id = dbus_connection.register_object("/org/mpris/MediaPlayer2", mpris_playlists);
                }

                debug("MPRIS objects registered");
            }
            catch(IOError e) {
                warning("Could not register dbus object (%s).", e.message);
            }
        }

        private void on_bus_acquired(DBusConnection connection, string name) {
            this.dbus_connection = connection;
            debug("DBus: Bus %s acquired", name);

            this.register_objects();
        }

        private void on_name_acquired(DBusConnection connection, string name) {
            debug("DBus: Name %s acquired.", name);
        }

        private void on_name_lost(DBusConnection connection, string name) {
            debug("DBus: Name %s lost.", name);
        }

        private void send_property_change(Variant dict) {

            var invalidated_builder = new VariantBuilder(new VariantType("as"));

            Variant[] arg_tuple = {
                new Variant("s", INTERFACE_NAME),
                dict,
                invalidated_builder.end()
            };
            Variant args = new Variant.tuple(arg_tuple);

            try {
                this.dbus_connection.emit_signal(null,
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
            if(!service.IntegratesService) {
               this.reset_data();
            }

            if(service.SupportsPlaylists) {

                if(playlist_id == 0) {
                    try {
                        playlist_id = dbus_connection.register_object("/org/mpris/MediaPlayer2", mpris_playlists);
                    } catch(IOError e) {
                        warning("Could not register dbus playlist object (%s).", e.message);
                    }
                }

            } else {
                if(playlist_id != 0) {
                    dbus_connection.unregister_object(playlist_id);
                    playlist_id = 0;
                }
            }
        }

        private void on_player_properties_changed(HashTable<string,Variant> dict) {

            if(!this.Enable || dbus_connection.closed)
                return;

	        bool has_metadata;
	        var data = this.get_player_properties_changed_data(dict, out has_metadata);

            if(has_metadata) {
                mpris_player.set_metadata(dict);
                data.insert("Metadata", mpris_player.Metadata);
            }

            this.send_property_change(data);
        }

        private void on_playlist_properties_changed(HashTable<string,Variant> dict) {

            if(!this.Enable || dbus_connection.closed)
                return;

	        var data = this.get_playlist_properties_changed_data(dict);

            this.send_property_change(data);
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

            mpris_player.reset_metadata();
            data.insert("Metadata", mpris_player.Metadata);

            this.send_property_change(data);

        }

        public HashTable<string, Variant> get_playlist_properties_changed_data(HashTable<string, Variant> dict) {

            HashTable<string, Variant> data = new HashTable<string, Variant>(str_hash, str_equal);

            dict.foreach ((key, val) => {
                switch(key) {
                    case PlaylistApi.Property.PLAYLIST_COUNT:
                        data.insert("PlaylistCount", val);
                        break;
                    case PlaylistApi.Property.ORDERINGS:
                        data.insert("Orderings", val);
                        break;
                    case PlaylistApi.Property.ACTIVE_MAYBE_PLAYLIST:
                        data.insert("ActivePlaylist", val);
                        break;
                }
            });

            return data;
        }

        public HashTable<string, Variant> get_player_properties_changed_data(HashTable<string, Variant> dict, out bool has_metadata) {

            HashTable<string, Variant> data = new HashTable<string, Variant>(str_hash, str_equal);
            bool _has_metadata = false;

            dict.foreach ((key, val) => {
                switch(key) {
                    case Player.Property.CAN_CONTROL:
                        data.insert("CanControl", val);
                        break;
                    case Player.Property.CAN_PLAY:
                        data.insert("CanPlay", val);
                        break;
                    case Player.Property.CAN_PAUSE:
                        data.insert("CanPause", val);
                        break;
                    case Player.Property.CAN_SEEK:
                        data.insert("CanSeek", val);
                        break;
                    case Player.Property.CAN_GO_NEXT:
                        data.insert("CanGoNext", val);
                        break;
                    case Player.Property.CAN_GO_PREVIOUS:
                        data.insert("CanGoPrevious", val);
                        break;
                    case Player.Property.CAN_SHUFFLE:
                        data.insert("CanShuffle", val);
                        break;
                    case Player.Property.CAN_REPEAT:
                        data.insert("CanRepeat", val);
                        break;
                    case Player.Property.CAN_LIKE:
                        data.insert("CanLike", val);
                        break;
                    case Player.Property.PLAYBACKSTATUS:
                        var playstatus = (PlayStatus) val.get_int64();
                        data.insert("PlaybackStatus", playstatus.to_string());
                        break;
                    case Player.Property.SHUFFLE:
                        data.insert("Shuffle", val);
                        break;
                    case Player.Property.REPEAT:
                        var repeat = (RepeatStatus) val.get_int64();
                        data.insert("LoopStatus", repeat.to_string());
                        break;
                    case Player.Property.VOLUME:
                        data.insert("Volume", val);
                        break;
                    case Player.Property.URL:
                    case Player.Property.ARTIST:
                    case Player.Property.TRACK:
                    case Player.Property.ALBUM:
                    case Player.Property.ART_URL:
                    case Player.Property.TRACK_LENGTH:
                        _has_metadata = true;
                        break;
                }
	        });

            has_metadata = _has_metadata;
            return data;
        }
    }

    [DBus(name = "org.mpris.MediaPlayer2")]
    public class MprisRoot : GLib.Object {

        public bool CanQuit          { get { return true;  } }
        public bool CanRaise         { get { return true;  } }
        public bool HasTrackList     { get { return false; } }
        public bool CanSetFullscreen { get { return true; } }

        private WebMusic webmusic;
        private Service service;

        public MprisRoot(WebMusic w, Service s) {
            webmusic = w;
            service = s;
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
            webmusic.Quit();
        }

        public void Raise() {
            webmusic.Raise();
        }
    }

    [DBus(name = "org.mpris.MediaPlayer2.Player")]
    public class MprisPlayer : GLib.Object {

        public signal void Seeked(int64 position);

        private Player player;

        public MprisPlayer(Player p) {
            player = p;
            player.Seeked.connect(on_seeked);
        }

        public string PlaybackStatus
        {
            owned get { return player.PlaybackStatus.to_string(); }
        }

        public string LoopStatus {
            owned get { return player.Repeat.to_string(); }
            set {
                RepeatStatus status = RepeatStatus.NONE;
                if(RepeatStatus.try_parse_name(value, out status)) {
                    player.Repeat = status;
                } else {
                    warning("Unknown LoopStatus. Ignoring request.");
                }

            }
        }

        public double Rate {
            get { return 1.0; }
            set {  }
        }

        public bool Shuffle {
            get { return player.Shuffle; }
            set { player.Shuffle = value; }
        }

        public double Volume {
            get { return player.Volume; }
            set { player.Volume = value; }
        }

        public int64 Position {
            get { return player.Position; }
        }

        public double MinimumRate   { get { return 1.0; } }
        public double MaximumRate   { get { return 1.0; } }

        private HashTable<string,Variant> _metadata = new HashTable<string,Variant>(str_hash, str_equal);
        public HashTable<string,Variant> Metadata { //a{sv}
            owned get {
                Variant variant = "/";
                _metadata.insert("mpris:trackid", variant); //TODO Provide valid trackid
                return _metadata;
            }
        }

        public bool   CanGoNext     { get { return player.CanGoNext;     } }
        public bool   CanGoPrevious { get { return player.CanGoPrevious; } }
        public bool   CanPlay       { get { return player.CanPlay;       } }
        public bool   CanPause      { get { return player.CanPause;      } }
        public bool   CanSeek       { get { return player.CanSeek;       } }
        public bool   CanControl    { get { return player.CanControl;    } }

        public void Next() {
            player.Next();
        }

        public void Previous() {
            player.Previous();
        }

        public void Pause() {
            player.Pause();
        }

        public void Stop() {
            player.Stop();
        }

        public void Play() {
            player.Play();
        }

        public void Seek(int64 offset) {
            //TODO: Implement
        }

        public void SetPosition(ObjectPath TrackId, int64 Position) {
            player.Position = Position;
            this.Seeked(Position);
        }

        public void PlayPause() {
            player.PlayPause();
        }

        [DBus (visible = false)]
        public void set_metadata(HashTable<string,Variant> dict) {

            _metadata = new HashTable<string,Variant>(str_hash, str_equal);

            dict.foreach ((key, val) => {
                switch(key) {
                    case Player.Property.URL:
                        _metadata.insert("xesam:url", val);
                        break;
                    case Player.Property.ARTIST:
                        _metadata.insert("xesam:artist", val);
                        break;
                    case Player.Property.TRACK:
                        _metadata.insert("xesam:title", val);
                        break;
                    case Player.Property.ALBUM:
                        _metadata.insert("xesam:album", val);
                        break;
                    case Player.Property.ART_FILE_LOCAL:
                        _metadata.insert("mpris:artUrl", val);
                        break;
                    case Player.Property.TRACK_LENGTH:
                        _metadata.insert("mpris:length", val);
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

        private void on_seeked(int64 position) {
            this.Seeked(position); // Forward signal
        }
    }

    [DBus(name = "org.mpris.MediaPlayer2.Playlists")]
    private class MprisPlaylists : GLib.Object {

        public signal void PlaylistChanged(Playlist playlist);

        private PlaylistApi playlist_api;

        public MprisPlaylists(PlaylistApi p) {
            playlist_api = p;
            playlist_api.PlaylistChanged.connect(this.on_playlist_changed);
        }

        public uint32 PlaylistCount {
            get { return playlist_api.PlaylistCount; }
        }

        public string[] Orderings {
            owned get { return playlist_api.Orderings; }
        }

        public MaybePlaylist ActivePlaylist {
            get { return playlist_api.ActivePlaylist; }
        }

        public void ActivatePlaylist(ObjectPath playlist_id) {
            playlist_api.activate_playlist(playlist_id);
        }

        public Playlist[] GetPlaylists(uint32 index, uint32 max_count, string order, bool reverse_order) {

            PlaylistOrdering ordering = PlaylistOrdering.USER;
            if(PlaylistOrdering.try_parse_name(order, out ordering)) {
                return playlist_api.get_playlists(index, max_count, ordering, reverse_order);
            } else {
                warning("Unknown ordering. Ignoring request to get playlists.");
                return new Playlist[0];
            }
        }

        private void on_playlist_changed(Playlist playlist) {
            this.PlaylistChanged(playlist);
        }
    }

}


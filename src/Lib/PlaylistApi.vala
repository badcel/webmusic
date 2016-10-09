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

    public enum PlaylistOrdering {
        ALPHABETICAL, // INT = 0
        CREATED,      // INT = 1
        MODIFIED,     // INT = 2
        PLAYED,       // INT = 3
        USER;         // INT = 4

        public string to_string() {

            //Strings are compatible to the MPRIS dbus-specification.
            //Do not change!

            string ret = "";

            switch(this) {
                case PlaylistOrdering.ALPHABETICAL:
                    ret = "Alphabetical";
                    break;
                case PlaylistOrdering.CREATED:
                    ret = "Created";
                    break;
                case PlaylistOrdering.MODIFIED:
                    ret = "Modified";
                    break;
                case PlaylistOrdering.PLAYED:
                    ret = "Played";
                    break;
                case PlaylistOrdering.USER:
                    ret = "User";
                    break;
            }

            return ret;
        }

        public static bool try_parse_name(string name, out PlaylistOrdering result = null) {

            bool ret = true;
            switch(name) {
                case "Alphabetical":
                    result = PlaylistOrdering.ALPHABETICAL;
                    break;
                case "Created":
                    result = PlaylistOrdering.CREATED;
                    break;
                case "Modified":
                    result = PlaylistOrdering.MODIFIED;
                    break;
                case "Played":
                    result = PlaylistOrdering.PLAYED;
                    break;
                case "User":
                    result = PlaylistOrdering.USER;
                    break;
                default:
                    result = PlaylistOrdering.USER;
                    ret = false;
                    break;
            }

            return ret;
        }
    }

    public struct Playlist {
        public ObjectPath id;
        public string name;
        public string icon;

        public Playlist(ObjectPath id, string name, string icon) {
            this.id   = id;
            this.name = name;
            this.icon = icon;
        }

        public string to_string() {
            return "<Playlist id:%s name:%s icon:%s>".printf(this.id, this.name, this.icon);
        }
    }

    public struct MaybePlaylist {
        public bool valid;
        public Playlist playlist;

        public MaybePlaylist() {
            this.valid = false;
            this.playlist = Playlist(new ObjectPath("/"), "", "");
        }

        public string to_string() {
            return "<MaybePlaylist valid:%s %s>".printf(this.valid.to_string(), playlist.to_string());
        }
    }

    public class PlaylistApi : BaseApi {

        private static PlaylistApi playlist_api;

        public signal void PropertiesChanged(HashTable<string, Variant> dict);
        public signal void PlaylistChanged(Playlist playlist);

        private MaybePlaylist active_playlist;

        public PlaylistApi() {
            base(ObjectType.PLAYLIST);
        }

        public static PlaylistApi get_instance() {
            if(playlist_api == null) {
                playlist_api = new PlaylistApi();
            }

            return playlist_api;
        }


        public uint32 PlaylistCount {
            get {
                uint32 ret = 0;

                var prop = this.get_adapter_property(Property.PLAYLIST_COUNT);
                if(prop != null && prop.is_of_type(VariantType.UINT32)) {
                    ret = prop.get_uint32();
                }

                return ret;
            }
        }

        public string[] Orderings {
            owned get {

                string[] ret = new string[0];

                var prop = this.get_adapter_property(Property.ORDERINGS);
                if(prop != null) {
                    if(prop.is_of_type(VariantType.ARRAY)) {

                        var count = prop.n_children();
                        ret = new string[count];

                        for(int i = 0; i < count; i++) {
                            var v = prop.get_child_value(i);

                            if(v.get_type().is_variant()) {
                                v = v.get_variant();
                            }

                            if(v.is_of_type(VariantType.STRING)) {
                                ret[i] = v.get_string();
                            } else {
                                warning("Could not get orderings. Wrong datatype (%s).", v.get_type_string());
                                return new string[0];
                            }
                        }
                    } else {
                        warning("Could not get orderings. Wrong datatype (%s).", prop.get_type_string());
                    }
                } else {
                    warning("Could not get orderings. Property is null.");
                }
                return ret;
            }
        }

        public weak MaybePlaylist ActivePlaylist {
            get {
                //Return a weak reference, because we own the active_playlist
                //and we keep the object the whole lifetime

                var prop = this.get_adapter_property(Property.ACTIVE_MAYBE_PLAYLIST);
                active_playlist = this.get_maybe_playlist(prop);

                return active_playlist;
            }
        }

        public Playlist[] get_playlists(uint32 index, uint32 max_count, PlaylistOrdering ordering, bool reverse_order) {

            Variant[] args = new Variant[4];
            args[0] = new Variant.uint32(index);
            args[1] = new Variant.uint32(max_count);
            args[2] = new Variant.int32((int32)ordering);
            args[3] = new Variant.boolean(reverse_order);

            var v = this.call_adapter_function(Action.GET_PLAYLISTS, args);

            if(v == null
                || !v.is_of_type(VariantType.ARRAY)) {
                warning("Could not get playlists. Wrong return type.");
                return new Playlist[0];
            }

            var count = v.n_children();

            Playlist[] playlists = new Playlist[count];

            for(int i = 0; i < count; i++) {
                playlists[i] = this.get_playlist(v.get_child_value(i));
            }
            return playlists;
        }

        public void activate_playlist(ObjectPath playlist_id) {

            Variant[] args = new Variant[1];
            args[0] = new Variant.object_path(playlist_id);

            this.call_adapter_function(Action.ACTIVATE_PLAYLIST, args);
        }

        protected override void signal_send(string signal_name, Variant? parameter) {
            if(signal_name == "PlaylistChanged" && parameter != null) {
                this.PlaylistChanged(this.get_playlist(parameter));
            }
        }

        protected override void properties_changed(HashTable<string, Variant> changes) {
            this.PropertiesChanged(changes);
        }

        private Playlist get_playlist(Variant playlist) {

            Playlist ret = Playlist(new ObjectPath("/"), "", "");

            Variant plist = playlist;

            if(plist.get_type().is_variant()) {
                plist = plist.get_variant();
            }

            if(!plist.is_of_type(VariantType.ARRAY)) {
                warning("Can not convert playlist. Type is no array but type <%s>.", plist.get_type_string());
                return ret;
            }

            var count = plist.n_children();
            if(count != 3) {
                warning("Can not convert playlist. Wrong count of data (%s/3).", count.to_string());
                return ret;
            }

            var id   = plist.get_child_value(0);
            var name = plist.get_child_value(1);
            var icon = plist.get_child_value(2);

            if(id.get_type().is_variant()) {
                id = id.get_variant();
            }

            if(name.get_type().is_variant()) {
                name = name.get_variant();
            }

            if(icon.get_type().is_variant()) {
                icon = icon.get_variant();
            }

            if(!id.is_of_type(VariantType.STRING)
                || !name.is_of_type(VariantType.STRING)
                || !icon.is_of_type(VariantType.STRING)) {

                warning("Can not convert playlist. Content is no string.");
                return ret;
            }

            ret.id   = new ObjectPath(id.get_string());
            ret.name = name.get_string();
            ret.icon = icon.get_string();

            return ret;
        }

        private MaybePlaylist get_maybe_playlist(Variant? maybe_playlist) {

            MaybePlaylist ret = MaybePlaylist();

            if(maybe_playlist == null
                || !maybe_playlist.is_of_type(VariantType.ARRAY)
                || maybe_playlist.n_children() != 2) {

                warning("Can not convert maybe playlist. Wrong type.");
                return ret;
            }

            var valid    = maybe_playlist.get_child_value(0);
            var playlist = maybe_playlist.get_child_value(1);

            if(valid.get_type().is_variant()) {
                valid = valid.get_variant();
            }

            if(!valid.is_of_type(VariantType.BOOLEAN)) {
                warning("Can not convert maybe playlist. Wrong type for valid field.");
                return ret;
            }

            ret.valid = valid.get_boolean();
            ret.playlist = this.get_playlist(playlist);

            return ret;
        }

        public class Property {
            public const string PLAYLIST_COUNT        = "count";
            public const string ORDERINGS             = "orderings";
            public const string ACTIVE_MAYBE_PLAYLIST = "activeMaybePlaylist";
        }

        private class Action {
            public const string GET_PLAYLISTS     = "actionGetPlaylists";
            public const string ACTIVATE_PLAYLIST = "actionActivatePlaylist";
        }
    }

}

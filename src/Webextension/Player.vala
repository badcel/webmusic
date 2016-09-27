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

using LibWebMusic;

namespace WebMusic.Webextension {

    [DBus(name = "org.WebMusic.Webextension.Player")]
    public abstract class Player : GLib.Object, IPlayerPropertiesChangedProvider {

        private uint mOwnerId;
        private DBusConnection mConnection;

        public signal void Seeked(int64 position);
        public signal void PropertiesChanged(HashTable<PlayerProperties, Variant> dict);

        public Player() {
            OwnBus();
        }

        ~Player() {
            ReleaseBus();
        }

        public abstract RepeatStatus Repeat         { get; set; }
        public abstract PlayStatus   PlaybackStatus { get; }

        public abstract bool CanGoNext      { get; }
        public abstract bool CanGoPrevious  { get; }
        public abstract bool CanPlay        { get; }
        public abstract bool CanPause       { get; }
        public abstract bool CanSeek        { get; }
        public abstract bool CanControl     { get; }
        public abstract bool CanShuffle     { get; }
        public abstract bool CanRepeat      { get; }
        public abstract bool CanLike        { get; }

        public abstract bool Shuffle        { get; set; }
        public abstract bool Like           { get; set; }

        public abstract double Volume       { get; set; }
        public abstract int64  Position     { get; set; }

        public abstract void Search(string term);
        public abstract void Show(string type, string id);

        public virtual void Next(){}
        public virtual void Previous(){}
        public virtual void Pause(){}
        public virtual void Stop(){}

        public virtual void Play() {
            // If Playback is started send seeked signal to avoid desync via DBus
            this.Seeked(this.Position);
        }

        public void PlayPause() {
            if(this.PlaybackStatus != PlayStatus.PLAY) {
                this.Play();
            } else {
                this.Pause();
            }
        }

        private bool OwnBus() {
            mOwnerId = Bus.own_name(BusType.SESSION,
                                        "org.WebMusic.Webextension",
                                         GLib.BusNameOwnerFlags.NONE,
                                         OnBusAcquired,
                                         OnNameAcquired,
                                         OnNameLost);
            return mOwnerId != 0;
        }

        private void ReleaseBus() {
            if(mOwnerId == 0)
                return;

            Bus.unown_name(mOwnerId);
            mOwnerId = 0;
        }

        private void OnBusAcquired(DBusConnection connection, string name) {
            this.mConnection = connection;
            try {
                debug("DBus: Bus %s acquired\n", name);
                connection.register_object("/org/WebMusic/Webextension", this);
            }
            catch(IOError e) {
                critical("DBus: Could not register player object. (%s)", e.message);
            }
        }

        private void OnNameAcquired(DBusConnection connection, string name) {
            debug("DBus: Name %s acquired.", name);
        }

        private void OnNameLost(DBusConnection connection, string name) {
            debug("DBus: Name %s lost.", name);
        }

        protected void send_property_change(HashTable<PlayerProperties, Variant> dict) {

            bool has_metadata;
            var data = this.get_properties_changed_data(dict, out has_metadata);
            var invalidated_builder = new VariantBuilder(new VariantType("as"));

            Variant[] arg_tuple = {
                new Variant("s", "org.WebMusic.Webextension.Player"),
                data,
                invalidated_builder.end()
            };
            Variant args = new Variant.tuple(arg_tuple);

            try {
                this.mConnection.emit_signal(null,
                                 "/org/WebMusic/Webextension",
                                 "org.freedesktop.DBus.Properties",
                                 "PropertiesChanged",
                                 args
                );

                //TODO Convenience function. Data got already send via emit_signal
                this.PropertiesChanged(dict);
            }
            catch(Error e) {
                critical("Error emmitting PropertiesChanged DBus signal. (%s)", e.message);
            }

        }
    }
}

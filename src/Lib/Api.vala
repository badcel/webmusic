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

    public enum ObjectType {

        API,       // INT = 0
        PLAYER,    // INT = 1
        PLAYLIST,  // INT = 2
        TRACKLIST; // INT = 3

        public string to_string() {

            string ret = "";

            switch(this) {
                case ObjectType.API:
                    ret = "API";
                    break;
                case ObjectType.PLAYER:
                    ret = "Player";
                    break;
                case ObjectType.PLAYLIST:
                    ret = "Playlist";
                    break;
                case ObjectType.TRACKLIST:
                    ret = "Tracklist";
                    break;
            }

            return ret;
        }
    }

    [DBus (name = "org.WebMusic.Webextension.Api")]
    public interface IDBusApi : GLib.Object {

        public signal void SignalSend(ObjectType type, string signal_name, Variant parameter);

        public abstract async void set_adapter_property(ObjectType type, string property, Variant value) throws IOError;
        public abstract async Variant get_adapter_property(ObjectType type, string property) throws IOError;
        public abstract async Variant call_adapter_function(ObjectType type, string name, Variant parameter) throws IOError;
    }

    public class Api : GLib.Object {

        private static Api api;

        private IDBusApi dbus_api;
        private uint watch_id = 0;

        public bool Ready { get; set;}

        public signal void SignalSend(ObjectType type, string signal_name, Variant? parameter);

        public static Api get_instance() {
            if(api == null) {
                api = new Api();
            }

            return api;
        }

        public Api() {
            this.Ready = false;
            this.watch_dbus();
        }

        ~Api() {
            this.unwatch_dbus();
        }

        private void watch_dbus() {
            debug("Waiting for webextension to be available via dbus...");

            this.watch_id = Bus.watch_name(BusType.SESSION,
                                "org.WebMusic.Webextension",
                                BusNameWatcherFlags.NONE,
                                on_bus_name_appeared,
                                on_bus_name_vanished);
        }

        private void unwatch_dbus() {

            if(this.watch_id == 0)
                return;

            Bus.unwatch_name(this.watch_id);
            this.watch_id = 0;
        }

        private void on_bus_name_appeared(DBusConnection connection, string name, string name_owner) {

            Bus.get_proxy.begin<IDBusApi>(BusType.SESSION, "org.WebMusic.Webextension",
                                        "/org/WebMusic/Webextension", 0, null, (obj, res) => {
                try {

                    dbus_api = Bus.get_proxy.end<IDBusApi>(res);
                    dbus_api.SignalSend.connect(this.on_signal_send);
                    this.Ready = true;

                    debug("Webextension appeared on dbus. Connected to %s. Api ready.", name);

                } catch(IOError e) {
                    warning("Webextension appeared on dbus. Could not connect (%s). Api not ready.", e.message);
                    this.Ready = false;
                }
            });
        }

        private void on_bus_name_vanished(DBusConnection connection, string name) {
            debug("Webextension vanished from dbus. Api not ready.");
            this.Ready = false;
        }

        private void on_signal_send(ObjectType type, string signal_name, Variant parameter) {

            Variant? v;
            if(parameter.is_of_type(VariantType.STRING) && parameter.get_string() == "/null/") {
                v = null;
            } else {
                v = parameter;
            }

            this.SignalSend(type, signal_name, v);
        }

        public void set_adapter_property(ObjectType type, string property, Variant value) {

            if(!this.Ready) {
                warning("Api is not ready. Please wait.");
                return;
            }

            dbus_api.set_adapter_property.begin(type, property, value, (obj, res) => {
                try {
                    dbus_api.set_adapter_property.end(res);
                } catch(Error e) {
                    warning("Could not set adapter property %s. Ignoring request. (%s)",property, e.message);
                }
            });
        }

        public Variant? get_adapter_property(ObjectType type, string property) {

            if(!this.Ready) {
                warning("Api is not ready. Please wait.");
                return null;
            }

            Variant? ret = null;
            var loop = new MainLoop();

            dbus_api.get_adapter_property.begin(type, property, (obj, res) => {
                try {
                    ret = dbus_api.get_adapter_property.end(res);
                } catch(Error e) {
                    warning("Could not get adapter property %s. Ignoring request. (%s)", property, e.message);
                    ret = null;
                } finally {
                    loop.quit();
                }
            });
            loop.run(); // wait until async method finishes

            if(ret.is_of_type(VariantType.STRING) && ret.get_string() == "/null/") {
              ret = null;
            }

            return ret;
        }

        public Variant? call_adapter_function(ObjectType type, string name, Variant? parameter) {

            if(!this.Ready) {
                warning("Api is not ready. Please wait.");
                return null;
            }

            Variant v;
            if(parameter == null) {
                //TODO Workaround until dbus supports maybe types: https://bugs.freedesktop.org/show_bug.cgi?id=27857
                v = new Variant.string("/null/");
            } else {
                v = parameter;
            }

            Variant? ret = null;
            var loop = new MainLoop();

            dbus_api.call_adapter_function.begin(type, name, v, (obj, res) => {
                try {
                    ret = dbus_api.call_adapter_function.end(res);

                    if(ret.is_of_type(VariantType.STRING) && ret.get_string() == "/null/") {
                        ret = null;
                    }
                } catch(Error e) {
                    warning("Could not call adapter function %s. Ignoring request. (%s)", name, e.message);
                    ret = null;
                } finally {
                    loop.quit();
                }
            });
            loop.run(); // wait until async method finishes

            return ret;
        }
    }

    protected abstract class BaseApi : GLib.Object {

        private HashTable<string, Variant> cache;
        private ObjectType type;
        private bool cache_properties = true;
        protected Api api;

        public bool CacheProperties {
            get { return this.cache_properties; }
            set {
                this.cache_properties = value;

                if(value) {
                    debug("Caching for properties of ObjectType %s enabled.", this.type.to_string());
                } else {
                    debug("Caching for properties of ObjectType %s disabled.", this.type.to_string());
                }
            }
        }

        public BaseApi(ObjectType t) {
            cache = new HashTable<string, Variant>(str_hash, str_equal);

            this.type = t;
            this.api = Api.get_instance();
            this.api.SignalSend.connect(on_signal_send);
        }

        protected abstract void signal_send(string signal_name, Variant? parameter);
        protected abstract void properties_changed(HashTable<string, Variant> changes);

        protected Variant? get_adapter_property(string property) {
            if(!api.Ready) {
                return null;
            }

            Variant? ret = null;

            if(this.CacheProperties && cache.contains(property)) {
                ret = cache.get(property);
            } else {
                ret = api.get_adapter_property(this.type, property);

                if(this.CacheProperties && ret != null) {
                    cache.set(property, ret);
                }
            }

            return ret;
        }

        protected Variant? call_adapter_function(string name, Variant? parameter) {
            if(!api.Ready) {
                return null;
            }

            return  api.call_adapter_function(this.type, name, parameter);
        }

        protected void on_signal_send(ObjectType t, string signal_name, Variant? parameter) {
            if(t != this.type) {
                //Signal is not relevant
                return;
            }

            Variant? v;
            if(parameter.is_of_type(VariantType.STRING) && parameter.get_string() == "/null/") {
                v = null;
            } else {
                v = parameter;
            }

            if(signal_name == "propertiesChanged") {
                if(v == null || !v.is_of_type(VariantType.DICTIONARY)) {
                    warning("Can not send PropertiesChanged signal. Parameter is not of type dictionary.");
                    return;
                }

                HashTable<string, Variant> dict = (HashTable<string, Variant>) parameter;

                if(this.CacheProperties) {
                    dict.foreach ((key, val) => {
                        cache.set(key, val);
                    });
                }

                this.properties_changed(dict);

            } else {
                this.signal_send(signal_name, v);
            }
        }

    }
}

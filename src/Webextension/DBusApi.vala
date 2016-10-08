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
using LibWebMusic;

namespace WebMusic.Webextension {

    [DBus(name = "org.WebMusic.Webextension.Api")]
    public class DBusApi: GLib.Object, ISignalSender {

        private uint owner_id;
        private DBusConnection dbus_connection;
        private IApiAdapter adapter;

        ~DBusApi() {
            release_bus();
        }

        public signal void SignalSend(ObjectType type, string signal_name, Variant parameter);

        [DBus(visible = false)]
        public void send_signal(ObjectType type, string name, Variant? parameter) {

            Variant v;
            if(parameter == null) {
                //TODO Workaround until dbus supports maybe types: https://bugs.freedesktop.org/show_bug.cgi?id=27857
                v = new Variant.string("/null/");
            } else {
                v = parameter;
            }

            this.SignalSend(type, name, v);
        }

        public async Variant get_adapter_property(ObjectType type, string property_name) {

            if(adapter == null) {
                warning("Missing adapter, get_adapter_property request ignored!");
                return new Variant.maybe(VariantType.BOOLEAN, null);;
            }

            Idle.add(get_adapter_property.callback);
		    yield;

            Variant? ret = adapter.get_adapter_property(type, property_name);

            if(ret == null) {
                ret = new Variant.string("/null/");
            }

            return ret;
        }

        public async void set_adapter_property(ObjectType type, string property_name, Variant value) {

            if(adapter == null) {
                warning("Missing adapter, set_adapter_property request ignored!");
                return;
            }

            Idle.add(set_adapter_property.callback);
		    yield;

            adapter.set_adapter_property(type, property_name, value);
        }

        public async Variant call_adapter_function(ObjectType type, string function_name, Variant parameter) {

            if(adapter == null) {
                warning("Missing adapter, call_adapter_function request ignored!");
                return new Variant.maybe(VariantType.BOOLEAN, null);;
            }

            Variant? v;
            if(parameter.is_of_type(VariantType.STRING) && parameter.get_string() == "/null/") {
                v = null;
            } else {
                v = parameter;
            }

            Idle.add(call_adapter_function.callback);
		    yield;

            Variant? ret = adapter.call_adapter_function(type, function_name, v);

            if(ret == null) {
                ret = new Variant.string("/null/");
            }

            return ret;
        }

        [DBus(visible = false)]
        public void set_adapter(IApiAdapter a) {
            this.adapter = a;
            this.adapter.set_signal_sender(this);
        }

        [DBus(visible = false)]
        public bool own_bus() {
            owner_id = Bus.own_name(BusType.SESSION,
                                        "org.WebMusic.Webextension",
                                         GLib.BusNameOwnerFlags.NONE,
                                         on_bus_acquired,
                                         on_name_acquired,
                                         on_name_lost);
            return owner_id != 0;
        }

        private void release_bus() {
            if(owner_id == 0)
                return;

            Bus.unown_name(owner_id);
            owner_id = 0;
        }

        private void on_bus_acquired(DBusConnection connection, string name) {
            this.dbus_connection = connection;
            try {
                connection.register_object("/org/WebMusic/Webextension", this);
            }
            catch(IOError e) {
                critical("DBus: Could not register player object. (%s)", e.message);
            }
        }

        private void on_name_acquired(DBusConnection connection, string name) {
            debug("DBus: Name %s acquired.", name);
        }

        private void on_name_lost(DBusConnection connection, string name) {
            debug("DBus: Name %s lost.", name);
        }
    }

}

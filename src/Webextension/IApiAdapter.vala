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

    public interface ISignalSender : GLib.Object {
        public abstract void send_signal(ObjectType type, string name, Variant? parameter);
    }

    public interface IApiAdapter : GLib.Object {

        public abstract void set_signal_sender(ISignalSender sender);
        public abstract Variant? get_adapter_property(ObjectType type, string property_name);
        public abstract void set_adapter_property(ObjectType type, string property_name, Variant value);
        public abstract Variant? call_adapter_function(ObjectType type, string function_name, Variant? parameter);

    }

}

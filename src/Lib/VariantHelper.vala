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

    public interface VariantHelper : GLib.Object {

        public static string[] get_string_array(Variant variant) {

            if(!variant.is_of_type(VariantType.ARRAY)) {
                warning("Can not convert variant into string[]. Array expected (%s).", variant.get_type_string());
                return new string[0];
            }

            var count = variant.n_children();
            string[] ret = new string[count];

            for(var i = 0; i < count; i++) {

                Variant v = variant.get_child_value(i);
                if(v.get_type().is_variant()) {
                    v = v.get_variant();
                }

                if(v.is_of_type(VariantType.STRING)) {
                    ret[i] = v.get_string();
                } else {
                    ret[i] = "";
                    warning("Can not set array element. Expected string datatype (%s).", v.get_type_string());
                }

            }

            return ret;
        }

    }
}

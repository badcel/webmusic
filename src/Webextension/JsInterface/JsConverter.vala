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

namespace WebMusic.Webextension.JsInterface {

    private class JsConverter : GLib.Object {

        public static JSCore.Value get_value(Variant? variant, JSCore.Context js_context) {
            if (variant == null) {
		        return new JSCore.Value.null(js_context);
            }

            if (variant.is_of_type(VariantType.STRING)) {
	            return new JSCore.Value.string(js_context, new JSCore.String.with_utf8_c_string(variant.get_string()));
            }

            if (variant.is_of_type(VariantType.BOOLEAN)) {
	            return new JSCore.Value.boolean(js_context, variant.get_boolean());
	        }

            if (variant.is_of_type(VariantType.DOUBLE)) {
	            return new JSCore.Value.number(js_context, variant.get_double());
            }

            if (variant.is_of_type(VariantType.INT32)) {
	            return new JSCore.Value.number(js_context, (double) variant.get_int32());
            }

            if (variant.is_of_type(VariantType.UINT32)) {
	            return new JSCore.Value.number(js_context, (double) variant.get_uint32());
            }

            if (variant.is_of_type(VariantType.INT64)) {
	            return new JSCore.Value.number(js_context, (double) variant.get_int64());
            }

            if (variant.is_of_type(VariantType.UINT64)) {
	            return new JSCore.Value.number(js_context, (double) variant.get_uint64());
            }

            warning("Given variant type could not be converted into a JSCore.Value");
            return new JSCore.Value.null(js_context);
        }

        public static Variant? get_variant(JSCore.Value value, JSCore.Context js_context) {
            JSCore.Value exception = null;
            Variant variant = null;

            var type = value.get_type(js_context);

            switch(type) {
                case JSCore.Type.Undefined:
                case JSCore.Type.Null:
                    variant = null;
                    break;
                case JSCore.Type.Boolean:
                    variant = new Variant.boolean(value.to_boolean(js_context));
                    break;
                case JSCore.Type.Number:
                    variant = new Variant.double((double)value.to_number(js_context, exception));
                    break;
                case JSCore.Type.String:
                    variant = new Variant.string(get_string(value, js_context));
                    break;
                case JSCore.Type.Object:
                    //TODO: Currently only VariantDicts are supported

                    var dict = new VariantDict();

                    var js_dict = value.to_object(js_context, exception);
                    JSCore.Object js_dict_entry;
                    unowned JSCore.PropertyNameArray property_names = js_dict.copy_property_names(js_context);

                    string key = "";
                    Variant v;
                    for (var i=0; i < property_names.get_count(); i++) {
                        js_dict_entry = js_dict.get_property_at_index (js_context, i, out exception).to_object(js_context, exception);
                        key = JsConverter.get_string(js_dict_entry.get_property_at_index (js_context, 0, out exception), js_context);
                        v = JsConverter.get_variant(js_dict_entry.get_property_at_index(js_context, 1, out exception), js_context);
                        dict.insert_value(key, v);
                    }
                    variant = dict.end();
                    break;
                default:
                    variant = null;
                    warning("Unknown JSCore.Type");
                    break;
            }

            return variant;
        }

        public static string get_string(JSCore.Value value, JSCore.Context js_context){
            JSCore.Value? exception = null;

            JSCore.String str = value.to_string_copy(js_context, exception);
            var ret = string.nfill(str.get_maximum_utf8_c_string_size(), ' ');
            str.get_utf8_c_string(ret, ret.length);

            return ret;
        }

    }

}

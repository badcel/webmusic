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

            string str = "";
            return get_variant_ex(value, js_context, 0, out str);
        }

        private static Variant? get_variant_ex(JSCore.Value value, JSCore.Context js_context, int layer, out string str) {
            str = "";
            JSCore.Value exception = null;
            Variant variant = null;

            var type = value.get_type(js_context);

            switch(type) {
                case JSCore.Type.Undefined:
                case JSCore.Type.Null:
                    variant = null;
                    str = "";
                    break;
                case JSCore.Type.Boolean:
                    bool b = value.to_boolean(js_context);
                    variant = new Variant.boolean(b);
                    str = b.to_string();
                    break;
                case JSCore.Type.Number:
                    double d = (double)value.to_number(js_context, exception);
                    variant = new Variant.double(d);
                    str = d.to_string();
                    break;
                case JSCore.Type.String:
                    string s = get_string(value, js_context);
                    variant = new Variant.string(s);
                    str = "'" + s + "'";
                    break;
                case JSCore.Type.Object:
                    variant = handle_object(value, js_context, layer, out str);
                    break;
                default:
                    variant = null;
                    warning("Unknown JSCore.Type");
                    break;
            }

            return variant;

        }

        //Handles javascript objects
        // - Converts an js array into an variant array
        // - Converts an js object into a variant dictionary
        private static Variant? handle_object(JSCore.Value value, JSCore.Context js_context, int layer, out string str) {
            str = "";
            Variant variant = null;
            JSCore.Value exception = null;

            var js_object = value.to_object(js_context, exception);

            if(value.is_array(js_context)) {

                var o = new JsObject.from_object(js_object, js_context);
                int length = (int) o.get_property_value("length").get_double();

                if(length == 0) {
                    str = "";
                    return null;
                }

                for (var i = 0; i < length; i++) {

                    string s = "";
                    var property = js_object.get_property_at_index(js_context, i, out exception);
                    get_variant_ex(property, js_context, layer + 1, out s);

                    if(s.length == 0) {
                        str = "";
                        warning("Array element contains unsupported data. No data returned.");
                        return null;
                    }

                    str += s;
                    if(i < length - 1) {
                        str += ", ";
                    }
                }

                bool isStructArrayEntry = layer > 0? true : false;
                if(isStructArrayEntry){
                    str = "(" + str + ")";
                } else {
                    //Regular array
                    str = "[" + str + "]";
                }

                if(layer == 0) {
                    //Data collection finished, create variant

                    try {
                        variant = Variant.parse(null, str, null, null);
                    } catch(VariantParseError e) {
                        variant = null;
                        str = "";
                        warning("Variant parse error with string: %s. (%s) ",str, e.message);
                    }
                }

            } else {
                //Treat objects as dictionaries

                var dict = new VariantDict();
                unowned JSCore.PropertyNameArray property_names = js_object.copy_property_names(js_context);

                string k = "";
                Variant v;

                JSCore.Value js_value;
                JSCore.String js_key;

                var count = property_names.get_count();
                for (var i = 0; i < count; i++) {
                    js_key = property_names.get_name_at_index(i);
                    js_value = js_object.get_property(js_context, js_key, out exception);

                    k = get_string_from_js_string(js_key, js_context);
                    v = get_variant_ex(js_value, js_context, layer + 1, out str);

                    dict.insert_value(k, v);
                }

                variant = dict.end();
                str = "";
            }

            return variant;
        }


        public static string get_string(JSCore.Value value, JSCore.Context js_context){
            JSCore.Value? exception = null;

            JSCore.String str = value.to_string_copy(js_context, exception);

            return get_string_from_js_string(str, js_context);
        }

        private static string get_string_from_js_string(JSCore.String str, JSCore.Context js_context) {
            var ret = string.nfill(str.get_maximum_utf8_c_string_size(), ' ');
            str.get_utf8_c_string(ret, ret.length);

            return ret;
        }

    }

}

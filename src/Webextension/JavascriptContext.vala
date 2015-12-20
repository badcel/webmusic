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

namespace WebMusic.Webextension {

    private class JavascriptContext : GLib.Object {

        public signal void ContextChanged();

        private unowned JSCore.GlobalContext mContext;
        private unowned JSCore.Object mJsInterface;
        private unowned JSCore.Object mGlobal;

        private static const string API_NAME = "WebMusicApi";

        public JavascriptContext(JSCore.GlobalContext context) {
            this.SetContext(context);
        }


        static const JSCore.StaticFunction[] js_funcs = {
            { "debug", debugJs, JSCore.PropertyAttribute.ReadOnly },
            { "warning", warningJs, JSCore.PropertyAttribute.ReadOnly },
            { null, null, 0 }
        };

        public static JSCore.Value debugJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            debug("Log from JS: %s", GetUTF8StringFromValue(arguments[0], ctx));
            return new JSCore.Value.boolean(ctx, true);
        }

        public static JSCore.Value warningJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            warning("Warning from JS: %s", GetUTF8StringFromValue(arguments[0], ctx));
            return new JSCore.Value.boolean(ctx, true);
        }

        public void SetContext(JSCore.GlobalContext context) {

            const JSCore.ClassDefinition definition = {
                0,                          // version
                JSCore.ClassAttribute.None, // attribute
                API_NAME,                   // className
                null,                       // parentClass

                null,                       // static values
                js_funcs,                   // static functions

                null,                       // initialize
                null,                       // finalize

                null,                       // hasProperty
                null,                       // getProperty
                null,                       // setProperty
                null,                       // deleteProperty

                null,                       // getPropertyNames
                null,                       // callAsFunction
                null,                       // callAsConstructor
                null,                       // hasInstance
                null                        // convertToType
            };

            var jsApiClass = new JSCore.Class(definition);
            var jsInterface = new JSCore.Object(context, jsApiClass, mContext);
            jsInterface.protect(context);

            var global = context.get_global_object();
            global.protect(context);

            var id = new JSCore.String.with_utf8_c_string(API_NAME);
            global.set_property(context, id, jsInterface, JSCore.PropertyAttribute.None, null);

            if(mJsInterface != null) {
                mJsInterface.unprotect(mContext);
            }

            if(mGlobal != null) {
                mGlobal.unprotect(mContext);
            }

            mGlobal = global;
            mContext = context;
            mJsInterface = jsInterface;

            this.ContextChanged();
        }

        public unowned JSCore.Value CallFunction(string name, Variant[]? parameter) {
            JSCore.Value? exception;
            unowned JSCore.Value ret = null;

            JSCore.Value val = mJsInterface.get_property(mContext,
                                new JSCore.String.with_utf8_c_string(name), out exception);

            //TODO Exception handling

            JSCore.Object? func = val.to_object(mContext, exception);

            if(func == null) {
                critical("Function %s is null.", name);
                //TODO: Raise Exception
            } else if(!func.is_function(mContext)) {
                critical("Function %s is no function.", name);
                //TODO: Raise Exception
            } else {
                void*[] params = new void*[0];
                if(parameter != null) {
                    params = new void*[parameter.length];
                    for(int i = 0; i < parameter.length; i++) {
                        params[i] = GetValueFromVariant(parameter[i], mContext);

                    }
                }

                ret = func.call_as_function(mContext, func, (JSCore.Value[]) params, out exception);
            }

            return ret;
        }

        public string CallFunctionAsString(string name, Variant[]? parameter) {
            unowned JSCore.Value? ret = CallFunction(name, parameter);
            return GetUTF8StringFromValue(ret, mContext);;
        }

        public int CallFunctionAsInteger(string name, Variant[]? parameter) {
            JSCore.Value? exception = null;
            unowned JSCore.Value? ret = CallFunction(name, parameter);

            return (int)ret.to_number(mContext, exception);
        }

        public double CallFunctionAsDouble(string name, Variant[]? parameter) {
            JSCore.Value? exception = null;
            unowned JSCore.Value? ret = CallFunction(name, parameter);

            return (double)ret.to_number(mContext, exception);
        }

        public bool CallFunctionAsBoolean(string name, Variant[]? parameter) {
            unowned JSCore.Value? ret = CallFunction(name, parameter);
            return ret.to_boolean(mContext);
        }

        public bool get_property(string name, out JSCore.Value value) {
            bool ret = false;
            value = new JSCore.Value.null(mContext);
            JSCore.Value? exception;

            JSCore.String jsName = new JSCore.String.with_utf8_c_string(name);

            if(!mJsInterface.has_property(mContext, jsName)) {
                ret = false;
            } else {
                ret = true;
                value = mJsInterface.get_property(mContext, jsName, out exception);
            }

            return ret;
        }

        public void EvaluateScript(string code, string path, int line) {
            JSCore.Value exception = null;
            mContext.evaluate_script(new JSCore.String.with_utf8_c_string(code), mJsInterface,
                                       new JSCore.String.with_utf8_c_string(path), line,
                                       out exception);


        }

        public static JSCore.Value GetValueFromVariant(Variant? variant, JSCore.Context context) {

            if (variant == null) {
		        return new JSCore.Value.null(context);
            }

            if (variant.is_of_type(VariantType.STRING)) {
	            return new JSCore.Value.string(context, new JSCore.String.with_utf8_c_string(variant.get_string()));
            }

            if (variant.is_of_type(VariantType.BOOLEAN)) {
	            return new JSCore.Value.boolean(context, variant.get_boolean());
	        }

            if (variant.is_of_type(VariantType.DOUBLE)) {
	            return new JSCore.Value.number(context, variant.get_double());
            }

            if (variant.is_of_type(VariantType.INT32)) {
	            return new JSCore.Value.number(context, (double) variant.get_int32());
            }

            if (variant.is_of_type(VariantType.UINT32)) {
	            return new JSCore.Value.number(context, (double) variant.get_uint32());
            }

            if (variant.is_of_type(VariantType.INT64)) {
	            return new JSCore.Value.number(context, (double) variant.get_int64());
            }

            if (variant.is_of_type(VariantType.UINT64)) {
	            return new JSCore.Value.number(context, (double) variant.get_uint64());
            }

            warning("Given variant type could not be converted into a JSCore.Value");
            return new JSCore.Value.null(context);
        }

        public string GetUTF8String(JSCore.Value val) {
            return GetUTF8StringFromValue(val, mContext);
        }

        public double GetDouble(JSCore.Value val) {
            JSCore.Value? exception = null;
            return (double)val.to_number(mContext, exception);
        }

        public int GetInteger(JSCore.Value val) {
            JSCore.Value? exception = null;
            return (int)val.to_number(mContext, exception);
        }

        public bool GetBoolean(JSCore.Value val) {
            return val.to_boolean(mContext);
        }

        private static string GetUTF8StringFromValue(JSCore.Value val, JSCore.Context context){
            JSCore.Value? exception = null;

            JSCore.String str = val.to_string_copy(context, exception);
            string ret = string.nfill(str.get_maximum_utf8_c_string_size(), ' ');
            str.get_utf8_c_string(ret, ret.length);

            return ret;
        }
    }
}

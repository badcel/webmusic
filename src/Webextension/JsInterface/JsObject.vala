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

namespace WebMusic.Webextension.JsInterface {

    errordomain JavascriptError {
        EVALUATE,
        GET_PROPERTY,
        TO_OBJECT,
        INVALID_OBJECT,
        CALL_AS_FUNCTION
    }

    private class JsObject : GLib.Object {

        public signal void ContextChanged();

        private unowned JSCore.Object js_object;
        private unowned JSCore.Context js_context;

        public JsObject() {
        }

        public JsObject.from_class(string name, JSCore.Class class, JSCore.Context context) {
            this.create_from_class(name, class, context);
        }

        public JsObject.from_object(JSCore.Object object, JSCore.Context context) {
            object.protect(context);

            js_object  = object;
            js_context = context;
        }

        public void create_from_class(string name, JSCore.Class class, JSCore.Context context){
            var obj = new JSCore.Object(context, class, context);
            obj.protect(context);

            var global_obj = context.get_global_object();
            global_obj.protect(context);

            var obj_name = new JSCore.String.with_utf8_c_string(name);
            global_obj.set_property(context, obj_name, obj, JSCore.PropertyAttribute.None, null);

            if(js_object != null) {
                js_object.unprotect(js_context);
            }

            js_object  = obj;
            js_context = context;

            this.ContextChanged();
        }

        public Variant? call_function(string name, Variant[]? parameter) throws JavascriptError {
            Variant? ret = null;
            JSCore.Value? exception;
            unowned JSCore.Value retFunc = null;

            JSCore.Value val = js_object.get_property(js_context,
                                new JSCore.String.with_utf8_c_string(name), out exception);

            if(exception != null) {
                var text = this.get_exception_text("get_property", exception);
                throw new JavascriptError.GET_PROPERTY(text);
            }

            JSCore.Object? func = val.to_object(js_context, exception);

            if(exception != null) {
                var text = this.get_exception_text("to_object", exception);
                throw new JavascriptError.TO_OBJECT(text);
            }

            if(func == null) {
                throw new JavascriptError.TO_OBJECT("Javascript function %s is null.".printf(name));
            } else if(!func.is_function(js_context)) {
                throw new JavascriptError.INVALID_OBJECT("Javascript function %s is no function.".printf(name));
            } else {
                void*[] params = new void*[0];
                if(parameter != null) {
                    params = new void*[parameter.length];
                    for(int i = 0; i < parameter.length; i++) {
                        params[i] = JsConverter.get_value(parameter[i], js_context);
                    }
                }

                retFunc = func.call_as_function(js_context, js_object, (JSCore.Value[]) params, out exception);

                if(exception != null) {
                    var text = this.get_exception_text("call_as_function_as_string", exception);
                    throw new JavascriptError.CALL_AS_FUNCTION(text);
                } else {
                    ret = JsConverter.get_variant(retFunc, js_context);
                }
            }

            return ret;
        }

        //This function can be used to avoid the call of the possibly unsafe call to JsConverter
        //for the return value of the called javascript function. If the returned value is no string
        //null will be returned.
        public string? call_function_as_string(string name, Variant[]? parameter) throws JavascriptError {
            string? ret = null;
            JSCore.Value exception = null;
            unowned JSCore.Value retFunc = null;

            JSCore.Value val = js_object.get_property(js_context,
                                new JSCore.String.with_utf8_c_string(name), out exception);

            if(exception != null) {
                var text = this.get_exception_text("get_property", exception);
                throw new JavascriptError.GET_PROPERTY(text);
            }

            JSCore.Object? func = val.to_object(js_context, exception);

            if(exception != null) {
                var text = this.get_exception_text("to_object", exception);
                throw new JavascriptError.TO_OBJECT(text);
            }

            if(func == null) {
                throw new JavascriptError.TO_OBJECT("Javascript function %s is null.".printf(name));
            } else if(!func.is_function(js_context)) {
                throw new JavascriptError.INVALID_OBJECT("Javascript function %s is no function.".printf(name));
            } else {
                void*[] params = new void*[0];
                if(parameter != null) {
                    params = new void*[parameter.length];
                    for(int i = 0; i < parameter.length; i++) {
                        params[i] = JsConverter.get_value(parameter[i], js_context);
                    }
                }

                retFunc = func.call_as_function(js_context, js_object, (JSCore.Value[]) params, out exception);

                if(exception != null) {
                    var text = this.get_exception_text("call_as_function_as_string", exception);
                    throw new JavascriptError.CALL_AS_FUNCTION(text);
                } else {
                    if(!retFunc.is_string(js_context)) {
                        ret = null;
                    } else {
                        ret = JsConverter.get_string(retFunc, js_context);
                    }
                }
            }

            return ret;
        }

        public Variant? get_property_value(string name) {
            Variant? ret = null;
            var value = new JSCore.Value.null(js_context);
            JSCore.Value? exception;

            JSCore.String jsName = new JSCore.String.with_utf8_c_string(name);

            if(!js_object.has_property(js_context, jsName)) {
                ret = null;
            } else {
                value = js_object.get_property(js_context, jsName, out exception);

                if(exception != null) {
                    this.LogException(name, exception);
                } else {
                    ret = JsConverter.get_variant(value, js_context);
                }

            }

            return ret;
        }

        public JsObject? get_property_object(string name) {
            JsObject? ret = null;
            JSCore.Value? exception;

            JSCore.String jsName = new JSCore.String.with_utf8_c_string(name);

            if(!js_object.has_property(js_context, jsName)) {
                ret = null;
            } else {
                var value = js_object.get_property(js_context, jsName, out exception);

                if(exception != null) {
                    this.LogException(name, exception);
                } else {
                    var object = value.to_object(js_context, exception);

                    if(exception != null) {
                        this.LogException(name, exception);
                    } else {
                        return new JsObject.from_object(object, js_context);
                    }
                }
            }

            return ret;
        }

        public void EvaluateScript(string code, string path, int line) throws JavascriptError {
            JSCore.Value exception = null;
            js_context.evaluate_script(new JSCore.String.with_utf8_c_string(code), js_object,
                                       new JSCore.String.with_utf8_c_string(path), line,
                                       out exception);

            if(exception != null) {
                var text = this.get_exception_text("evaluate_script", exception);
                throw new JavascriptError.EVALUATE(text);
            }
        }

        protected void LogException(string name, JSCore.Value exception){
            warning(this.get_exception_text(name, exception));
        }

        protected string get_exception_text(string name, JSCore.Value exception) {
            JSCore.Value e = null;
            JSCore.Object o = exception.to_object(js_context, e);

            JSCore.String prop_name = new JSCore.String.with_utf8_c_string("line");
            double line = o.get_property(js_context, prop_name, out e).to_number(js_context, e);

            prop_name = new JSCore.String.with_utf8_c_string("sourceURL");
            string file = JsConverter.get_string(o.get_property(js_context, prop_name, out e), js_context);

            string message = JsConverter.get_string(exception, js_context);

            return "JS error during call of function '%s'\n\t- Message: %s\n\t- Line: %s\n\t- File: %s".printf(
                    name, message, line.to_string(), file);
        }
    }
}

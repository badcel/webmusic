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
            { "log", logJs, JSCore.PropertyAttribute.ReadOnly },
            { null, null, 0 }
        };
        
	    public static JSCore.Value logJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;
            
            debug("Log from JS: %s", GetUTF8StringFromValue(arguments[0], ctx));			
            return new JSCore.Value.boolean(ctx, true);
        }
        
        public void SetContext(JSCore.GlobalContext context) {

            const JSCore.ClassDefinition definition = {
                0,	// version
                JSCore.ClassAttribute.None,	// attribute
                API_NAME,	// className
                null,		// parentClass

                null,		// static values
                js_funcs,	// static functions

                null,		// initialize
                null,		// finalize

                null,		// hasProperty
                null,		// getProperty
                null,		// setProperty
                null,		// deleteProperty

                null,		// getPropertyNames
                null,		// callAsFunction
                null,		// callAsConstructor
                null,		// hasInstance
                null		// convertToType
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
        
        public unowned JSCore.Value CallFunction(string name) {
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
                ret = func.call_as_function(mContext, func, (JSCore.Value[]) params, out exception);
            }
                    
            return ret;
        }
        
        public string CallFunctionAsString(string name) {
            unowned JSCore.Value? ret = CallFunction(name);
            return GetUTF8StringFromValue(ret, mContext);;
        }
        
        public int CallFunctionAsInteger(string name) {
            JSCore.Value? exception = null;
            unowned JSCore.Value? ret = CallFunction(name);
            
            return (int)ret.to_number(mContext, exception);
        }
        
        public bool CallFunctionAsBoolean(string name) {
            unowned JSCore.Value? ret = CallFunction(name);
            return ret.to_boolean(mContext);
        }
        
        public void EvaluateScript(string code, string path, int line) {
            JSCore.Value exception = null;
            mContext.evaluate_script(new JSCore.String.with_utf8_c_string(code), mJsInterface,
                                       new JSCore.String.with_utf8_c_string(path), line,
                                       out exception);
            
            
        }
        
        private static string GetUTF8StringFromValue(JSCore.Value val, JSCore.Context context){
            JSCore.Value? exception = null;
            
            JSCore.String str = val.to_string_copy(context, exception);
            string ret = string.nfill(str.get_length() + 1, ' ');
            str.get_utf8_c_string(ret, ret.length);

            return ret;
        }
    }
}

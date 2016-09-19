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
using WebMusic.Webextension.JsInterface;

namespace WebMusic.Webextension {

    public enum JsApiType {
        PLAYER,    // INT = 0
        PLAYLIST,  // INT = 1
        TRACKLIST; // INT = 2

        public string to_string() {

            string ret = "";

            switch(this) {
                case JsApiType.PLAYER:
                    ret = "Player";
                    break;
                case JsApiType.PLAYLIST:
                    ret = "Playlist";
                    break;
                case JsApiType.TRACKLIST:
                    ret = "Tracklist";
                    break;
            }

            return ret;
        }
    }

    private class JsApi : GLib.Object{

        private const int REQUIRED_API_VERSION = 1;
        private static const string API_NAME = "WebMusicApi";
        private static JsApi? mSelf = null;

        public signal void PropertiesChanged(JsApiType type, HashTable<string, Variant> dict);
        public signal void SignalSend(JsApiType type, string name, Variant params);

        private Service service;
        private JsObject js_api;
        private JavascriptMusicPlayer js_player;

        private bool api_ready = false;

        public JsApi(Service s){

            service = s;

            js_api = new JsObject();
            js_api.ContextChanged.connect(OnContextChanged);

            mSelf = this;
        }

        public bool Ready {
            get { return this.api_ready;}
        }

        public JavascriptMusicPlayer Player {
            get { return this.js_player; }
        }

        public Service WebService {
            get { return service; }
        }

        public void set_context(JSCore.GlobalContext context) {
            var apiClass = new JSCore.Class(definition);
            this.js_api.create_from_class(API_NAME, apiClass, context);
        }

        public JsObject get_js_property(string object) {
            return js_api.get_property_object(object);
        }


        private static const JSCore.StaticFunction[] js_funcs = {
            { "debug", debugJs, JSCore.PropertyAttribute.ReadOnly },
            { "warning", warningJs, JSCore.PropertyAttribute.ReadOnly },
            { "sendPropertyChange", sendPropertyChange, JSCore.PropertyAttribute.ReadOnly },
            { "sendSignal", sendSignal, JSCore.PropertyAttribute.ReadOnly},
            { "activateApiFeature", activateApiFeature, JSCore.PropertyAttribute.ReadOnly},
            { null, null, 0 }
        };

        private const JSCore.ClassDefinition definition = {
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

        private static JSCore.Value debugJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            if(arguments.length == 2) {
                var type = JsConverter.get_variant(arguments[0], ctx);
                var type_string = ((JsApiType) type.get_double()).to_string();

                var text = JsConverter.get_string(arguments[1], ctx);

                debug("Log from JS (%s): %s", type_string, text);
            } else {
                warning("Can not log message from javascript. Wrong parameter count.");
            }

            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value warningJs (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            if(arguments.length == 2) {
                var type = JsConverter.get_variant(arguments[0], ctx);
                var type_string = ((JsApiType) type.get_double()).to_string();

                var text = JsConverter.get_string(arguments[1], ctx);

                warning("Warning from JS: (%s) %s", type_string, text);
            } else {
                warning("Can not log message from javascript. Wrong parameter count.");
            }

            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value sendPropertyChange (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            if(arguments.length == 2) {
                var type = JsConverter.get_variant(arguments[0], ctx);
	            HashTable<string, Variant> dict = (HashTable<string, Variant>) JsConverter.get_variant(arguments[1], ctx);

                if(type != null) {
                    var api_type = (JsApiType) type.get_double();
                    mSelf.PropertiesChanged(api_type, dict);
                } else {
                    warning("Can not send property change. Unknown type.");
                }
            } else {
                warning("Can not send property change. Wrong parameter count.");
            }

            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value sendSignal (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            if(arguments.length == 3) {
                var type = JsConverter.get_variant(arguments[0], ctx);

                if(type != null) {
                    var api_type = (JsApiType) type.get_double();
                    var name = JsConverter.get_string(arguments[1], ctx);
                    var params = JsConverter.get_variant(arguments[2], ctx);

                    mSelf.SignalSend(api_type, name, params);
                } else {
                    warning("Can not send signal. Unknown type.");
                }
            } else {
                warning("Can not send signal. Wrong parameter count.");
            }

            return new JSCore.Value.boolean(ctx, true);
        }

        private static JSCore.Value activateApiFeature (JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            //TODO

            return new JSCore.Value.boolean(ctx, true);
        }

        private void InjectApi() {
            if(service.ApiVersion != REQUIRED_API_VERSION) {
                api_ready = false;
                warning("Service %s is not supporting required API Version %i." +
                    " Integration not loaded.", service.Name, REQUIRED_API_VERSION);
            } else if(service.IntegratesService) {
                string serviceFile;
                string baseApi;
                string path;

                try {
                    path = Directory.GetServiceDir() + "api.js";
                    FileUtils.get_contents(path, out baseApi);

                    path = service.IntegrationFilePath;
                    FileUtils.get_contents(path, out serviceFile);

                    debug("Injecting %s: %s", service.Ident, path);

                    js_api.EvaluateScript(baseApi, path, 1);
                    js_api.EvaluateScript(serviceFile, path, 1);
                    api_ready = true;

                    js_api.call_function("init", null);

                } catch(FileError e) {
                    api_ready = false;

                    critical("Could not load content of service file (%s). " +
                            "Integration disabled. (%s)", path, e.message);
                }

            } else {
                api_ready = false;
                debug("No integration supported for service %s.", service.Name);
            }
        }

        private void OnContextChanged() {
            this.InjectApi();
            js_player = new JavascriptMusicPlayer(this);
        }

    }

}

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

    public enum JsAction {
        GET_PROPERTY,  // INT = 0
        SET_PROPERTY,  // INT = 1
        CALL_FUNCTION, // INT = 2
        SEND_SIGNAL;   // INT = 3

        public string to_string() {

            string ret = "";

            switch(this) {
                case JsAction.GET_PROPERTY:
                    ret = "get_property";
                    break;
                case JsAction.SET_PROPERTY:
                    ret = "set_property";
                    break;
                case JsAction.CALL_FUNCTION:
                    ret = "call_function";
                    break;
                case JsAction.SEND_SIGNAL:
                    ret = "send_signal";
                    break;
            }

            return ret;
        }
    }

    private class JsCommand : GLib.Object, Json.Serializable {

        public ObjectType Type  { get; set; }
        public JsAction Action    { get; set; }
        public string Identifier  { get; set; }
        public Variant? Parameter { get; set; }

        public JsCommand(ObjectType type, JsAction action,
            string identifier, Variant? params) {

            this.Type = type;
            this.Action = action;
            this.Identifier = identifier;
            this.Parameter = params;
        }

        public string to_json() {
            return Json.gobject_to_data(this, null);
        }

        public static JsCommand from_json(string json) throws GLib.Error {
            return Json.gobject_from_data (typeof (JsCommand), json) as JsCommand;
        }

        public string to_string() {
            StringBuilder builder = new StringBuilder ();
		    builder.append_printf ("Type=<%d> ", this.Type);
		    builder.append_printf ("Action=<%d> ", this.Action);
		    builder.append_printf ("Identifier=<%s> ", this.Identifier);

		    if(this.Parameter != null) {
		        builder.append_printf ("Parameter=Variant Type <%s>", this.Parameter.get_type_string());
		    }
		    return (owned) builder.str;
        }

        public new bool deserialize_property (string property_name, out Value value, ParamSpec pspec, Json.Node property_node) {

            value = Value(typeof (int));
            bool ret = false;

            switch(property_name) {
                case "Type":
                case "Action":
                    value = Value(typeof (int));
                    value.set_int((int)property_node.get_int());
                    ret = true;
                    break;
                case "Identifier":
                    value = Value(typeof (string));
                    value.set_string(property_node.get_string());
                    ret = true;
                    break;
                case "Parameter":
                    value = Value(typeof (string));
                    if(property_node.is_null()) {
                        value.set_string("<null>");
                    } else {
                        value.set_string(property_node.get_string());
                    }
                    ret = true;
                    break;
                default:
                    warning("Unknown property %s", property_name);
                    ret = false;
                    break;
            }

            return ret;
        }

        public new unowned ParamSpec find_property (string name) {
            Type type = typeof (JsCommand);
	        ObjectClass ocl = (ObjectClass) type.class_ref();
	        return ocl.find_property(name);
        }

        public new Value get_property (ParamSpec pspec) {

            Value value = Value(typeof (int));

            switch(pspec.get_name()) {
                case "Type":
                    value = Value(typeof (int));
                    value.set_int((int) this.Type);
                    break;
                case "Action":
                    value = Value(typeof (int));
                    value.set_int((int) this.Action);
                    break;
                case "Identifier":
                    value = Value(typeof (string));
                    value.set_string(this.Identifier);
                    break;
                case "Parameter":
                    value = Value(typeof (string));
                    if(this.Parameter == null) {
                        value.set_string("<null>");
                    } else {
                        value.set_string(Json.gvariant_serialize_data(this.Parameter, null));
                    }
                    break;
                default:
                    warning("Unknown property %s", pspec.get_name());
                    break;
            }

            return value;
        }

        public new Json.Node serialize_property (string property_name, Value value, ParamSpec pspec) {

            Json.Node node = null;
            switch(property_name) {
                case "Type":
                case "Action":
                    node = new Json.Node(Json.NodeType.VALUE);
                    node.set_int(value.get_int());
                    break;
                case "Identifier":
                    node = new Json.Node(Json.NodeType.VALUE);
                    node.set_string(value.get_string());
                    break;
                case "Parameter":
                    var json = value.get_string();
                    if(json == "<null>") {
                        node = null; //Do not serialize property
                    } else {
                        node = new Json.Node(Json.NodeType.VALUE);
                        node.set_string(json);
                    }
                    break;
                default:
                    warning("Unknown property %s", property_name);
                    break;
            }

            return node;
        }

        public new void set_property (ParamSpec pspec, Value value) {

            switch(pspec.get_name()) {
                case "Type":
                    this.Type = (ObjectType) value.get_int();
                    break;
                case "Action":
                    this.Action = (JsAction) value.get_int();
                    break;
                case "Identifier":
                    this.Identifier = value.get_string();
                    break;
                case "Parameter":
                    var json = value.get_string();
                    if(json == "<null>") {
                        this.Parameter = null;
                    } else {
                        try {
                            this.Parameter = Json.gvariant_deserialize_data (json, -1, null);
                        } catch(GLib.Error e) {
                           warning("Could not deserialize property Parameter (%s).", e.message);
                           this.Parameter = null;
                        }
                    }
                    break;
                default:
                    warning("Unknown property %s", pspec.get_name());
                    break;
            }
        }
    }


    public class JsAdapter : GLib.Object, IApiAdapter {

        private const int REQUIRED_API_VERSION = 1;
        private static const string API_NAME = "WebMusic";
        private static JsAdapter? self = null;

        private ISignalSender signal_sender;
        private Service service;
        private JsObject js_api;
        private JsObject js_global_object;

        public JsAdapter(Service s){

            service = s;
            self = this;
            js_global_object = new JsObject();
        }

        public void set_signal_sender(ISignalSender sender) {
            this.signal_sender = sender;
        }

        public void send_signal(ObjectType type, string name, Variant? parameter) {
            this.signal_sender.send_signal(type, name, parameter);
        }

        public Variant? get_adapter_property(ObjectType type, string property_name) {

            if(js_api == null) {
                warning("js_api is not ready. Request for get_property ignored.");
                return null;
            }

            var command = new JsCommand(type, JsAction.GET_PROPERTY, property_name, null);
            return this.send_command(command);
        }

        public void set_adapter_property(ObjectType type, string property_name, Variant value) {

            if(js_api == null) {
                warning("js_api is not ready. Request for set_property ignored.");
                return;
            }

            var command = new JsCommand(type, JsAction.SET_PROPERTY, property_name, value);
            this.send_command(command);
        }

        public Variant? call_adapter_function(ObjectType type, string function_name, Variant? parameter) {

            if(js_api == null) {
                warning("js_api is not ready. Request for call_function ignored.");
                return null;
            }

            var command = new JsCommand(type, JsAction.CALL_FUNCTION, function_name, parameter);
            return this.send_command(command);
        }

        public void set_context(JSCore.GlobalContext context) {
            var apiClass = new JSCore.Class(definition);
            this.js_global_object.create_from_class(API_NAME, apiClass, context);
            this.inject_js_api();
        }

        private Variant? send_command(JsCommand command){

            Variant? ret = null;
            Variant[] args = new Variant[1];
            args[0] = new Variant.string(command.to_json());

            try {
                var str = js_api.call_function_as_string("_handleJsonCommand", args);

                if(str != null) {
                    try {
                        ret = Json.gvariant_deserialize_data(str, -1, null);
                    } catch(GLib.Error e) {
                        warning("Could not deserialize json data from command reply (%s).", e.message);
                        ret = null;
                    }
                } else {
                    ret = null;
                }
            } catch(JavascriptError e) {
                warning("Could not call javascript function _handleJsonCommand (%s).", e.message);
                ret = null;
            }

            return ret;
        }

        private static const JSCore.StaticFunction[] js_funcs = {
            { "handleJsonCommand", handle_json_command, JSCore.PropertyAttribute.ReadOnly},
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

        private static JSCore.Value handle_json_command(JSCore.Context ctx,
            JSCore.Object function,
            JSCore.Object thisObject,
            JSCore.Value[] arguments,
            out JSCore.Value exception) {

            exception = null;

            try {
                if(!arguments[0].is_string(ctx)) {
                    warning("Expecting string to handle command. Command ignored.");
                    return new JSCore.Value.boolean(ctx, true);
                }

                string json = JsConverter.get_string(arguments[0], ctx);
                var obj = JsCommand.from_json(json);

                if(obj.Action == JsAction.CALL_FUNCTION) {

                    if(obj.Parameter == null) {
                        warning("Missing parameter in command. Ignoring command.");
                    } else {
                        if(obj.Identifier == "warning"
                            && obj.Parameter.is_of_type(VariantType.STRING)) {

                            var type_text = obj.Type.to_string();
                            var text = obj.Parameter.get_string();

                            warning("Warning from JS: (%s) %s", type_text, text);

                        } else if(obj.Identifier == "debug"
                            && obj.Parameter.is_of_type(VariantType.STRING)) {

                            var type_text = obj.Type.to_string();
                            var text = obj.Parameter.get_string();

                            debug("Debug from JS: (%s) %s", type_text, text);

                        } else if(obj.Identifier == "ping"
                            && obj.Parameter.is_of_type(VariantType.STRING)) {

                            var text = obj.Parameter.get_string() + " Ho!";
                            var cmd = new JsCommand(obj.Type, JsAction.CALL_FUNCTION, "pong", text);
                            var ret = self.send_command(cmd);

                            if(ret != null && ret.is_of_type(VariantType.STRING)) {
                                debug("Got pong response: %s", ret.get_string());
                            }
                        }
                    }

                } else if(obj.Action == JsAction.SEND_SIGNAL) {
                    self.send_signal(obj.Type, obj.Identifier, obj.Parameter);
                }
            } catch(Error e) {
                warning("Could not parse json data. Ignoring command (%s).", e.message);
            }

            return new JSCore.Value.boolean(ctx, true);
        }

        private void inject_js_api() {
            if(service.ApiVersion != REQUIRED_API_VERSION) {
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

                    js_global_object.EvaluateScript(baseApi, path, 1);
                    js_global_object.EvaluateScript(serviceFile, path, 1);

                    js_global_object.call_function("init", null);

                    js_api = js_global_object.get_property_object("Api");
                } catch(FileError e) {
                    critical("Could not load content of service file (%s). " +
                            "Integration disabled. (%s)", path, e.message);
                } catch(JavascriptError e) {
                    warning(e.message);
                }

            } else {
                debug("No integration supported for service %s.", service.Name);
            }
        }

    }

}

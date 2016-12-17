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

namespace LibWebMusic {

    public interface PlayerPlugin : Object {

        public abstract PlayerApi player_api { get; construct set; }
        public abstract PlaylistApi playlist_api { get; construct set; }

		public abstract void activate();
		public abstract void deactivate();
    }

    public class PluginManager : Object {

        private Peas.ExtensionSet extensions { get; set; }
        private Peas.Engine engine;

        PlayerApi player_api;
        PlaylistApi playlist_api;

        public PluginManager() {
            player_api = PlayerApi.get_instance();
            playlist_api = PlaylistApi.get_instance();
        }

        public void init() {

            this.engine = Peas.Engine.get_default();

			engine.add_search_path(
			    Config.PKG_LIB_DIR_PLUGINS,
			    Config.PKG_DATA_DIR_PLUGINS);

			extensions = new Peas.ExtensionSet(engine, typeof (LibWebMusic.PlayerPlugin),
			    "player_api", player_api,
			    "playlist_api", playlist_api);
			extensions.extension_added.connect((info, extension) => {
				(extension as LibWebMusic.PlayerPlugin).activate();
			});
			extensions.extension_removed.connect((info, extension) => {
				(extension as LibWebMusic.PlayerPlugin).deactivate();
			});
        }

        public void load_plugin(string name) {
            var plugin_info = engine.get_plugin_info(name);

            if(plugin_info != null) {
                engine.try_load_plugin(plugin_info);
            }
        }

        public void unload_plugin(string name) {
            var plugin_info = engine.get_plugin_info(name);

            if(plugin_info != null) {
                engine.try_unload_plugin(plugin_info);
            }
        }
    }
}

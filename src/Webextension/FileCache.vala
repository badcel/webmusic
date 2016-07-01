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

namespace WebMusic.Webextension {

    private class FileCache {

        public signal void file_cached(string file_name, bool success);

        public void cache_async(string url, string target_file) {
            var cached_file = File.new_for_path(target_file);

            if(!cached_file.query_exists()) {

                var online_file = File.new_for_uri(url);
                online_file.load_contents_async.begin(null, (obj, res) => {

                    try {
                        uint8[] contents;
                        string etag_out;

                        online_file.load_contents_async.end(res, out contents, out etag_out);

                        FileOutputStream os = cached_file.append_to(FileCreateFlags.NONE);
                        os.write(contents);
                        os.close();

                        this.file_cached(target_file, true);

                    } catch (Error e) {
                        warning("Could not cache file. (%s)", e.message);
                        this.file_cached(target_file, false);
                    }

                });
            } else {
                debug("File already cached ignoring request. (%s)", target_file);
                this.file_cached(target_file, true);
            }
        }
    }
}

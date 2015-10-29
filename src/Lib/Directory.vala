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

namespace LibWebMusic {

    public class Directory {

        public static string GetDataDir() {
                return Environment.get_user_data_dir() + "/" + Config.PACKAGE + "/";
        }

        public static string GetAlbumArtDir() {
                return Directory.GetDataDir() + "covers/";
        }

        public static string GetCookiesFile() {
                return Directory.GetDataDir() + "cookies.txt";
        }

        public static string GetServiceDir() {
            return Config.PKG_DATA_DIR + "/Services/";
        }

    }

}

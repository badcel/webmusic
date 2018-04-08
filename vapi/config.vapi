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

[CCode (lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
	public const string GETTEXT_PACKAGE;
	public const string LOCALE_DIR;
	public const string THEME_DIR;
	public const string PKG_DATA_DIR;
    public const string PKG_DATA_DIR_PLUGINS;
	public const string PKG_LIB_DIR;
	public const string PKG_LIB_DIR_PLUGINS;
	public const string PACKAGE_NAME;
	public const string PACKAGE_VERSION;
	public const string PACKAGE;
}


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

namespace WebKit {

    [Compact]
    [CCode (cheader_filename = "webkit2/webkit2.h")]
    private class Version {
        [CCode (cname = "WEBKIT_MAJOR_VERSION")]
	    public const int MAJOR;
	    [CCode (cname = "WEBKIT_MINOR_VERSION")]
	    public const int MINOR;
	    [CCode (cname = "WEBKIT_MICRO_VERSION")]
	    public const int MICRO;


	    public static uint major {
	        [CCode (cname = "webkit_get_major_version")]
	        get;
	    }

	    public static uint minor {
	        [CCode (cname = "webkit_get_minor_version")]
	        get;
	    }

	    public static uint micro {
	        [CCode (cname = "webkit_get_micro_version")]
	        get;
	    }
	}
}

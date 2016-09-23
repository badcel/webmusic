 #
 #   Copyright (C) 2014  Marcel Tiede
 #
 #   This program is free software: you can redistribute it and/or modify
 #   it under the terms of the GNU General Public License as published by
 #   the Free Software Foundation, either version 3 of the License, or
 #   (at your option) any later version.
 #
 #   This program is distributed in the hope that it will be useful,
 #   but WITHOUT ANY WARRANTY; without even the implied warranty of
 #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 #
 #   You should have received a copy of the GNU General Public License
 #   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 #

add_subdirectory(Lib)
add_subdirectory(Browser)
add_subdirectory(Webextension)
add_subdirectory(SearchProvider)
install(DIRECTORY Resources/Services 
        DESTINATION "${PKG_DATADIR}"
        PATTERN "*.in" EXCLUDE)

webmusic_configure(FILES desktop example.ini ${PKG_DATADIR}/Services/example ${CMAKE_CURRENT_SOURCE_DIR}/Resources/Services/example)

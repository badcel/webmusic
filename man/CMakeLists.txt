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

add_custom_command(OUTPUT webmusic.1
                   COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/help2man -N -i ${CMAKE_CURRENT_SOURCE_DIR}/include.webmusic -L en_US.UTF-8 ${CMAKE_BINARY_DIR}/src/Browser/webmusic -o webmusic.1
                   DEPENDS webmusic)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/webmusic.1 DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/man/man1")

add_custom_target(man ALL DEPENDS webmusic.1)

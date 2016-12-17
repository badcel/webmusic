 #
 #   Copyright (C) 2016  Marcel Tiede
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

vala_precompile(VALA_C
    Notification.vala
OPTIONS
    ${VALAFLAGS}
PACKAGES
    glib-2.0
    libnotify
    libpeas-1.0
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/src/Lib/libwebmusic.vapi
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
)

add_library(notification SHARED ${VALA_C})
target_link_libraries(notification webmusic ${GLIB_LDFLAGS} ${NOTIFY_LDFLAGS} ${LIBPEAS_LDFLAGS})
set_target_properties(notification PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${NOTIFY_CFLAGS} ${LIBPEAS_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/src/Lib")
install(TARGETS notification DESTINATION "${PKG_LIBDIR_PLUGINS}/notification")

install(FILES notification.plugin
        DESTINATION "${PKG_LIBDIR_PLUGINS}/notification")


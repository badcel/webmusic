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

vala_precompile(VALA_C_LIB_WEBMUSIC_COMMON
    Namespace.vala
    IPlayer.vala
    Service.vala
    Directory.vala
OPTIONS
    ${VALAFLAGS}
PACKAGES
    glib-2.0
    gio-2.0
CUSTOM_VAPIS
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
GENERATE_VAPI
    libwebmusic
GENERATE_HEADER
    libwebmusic
GENERATE_GIR
    libwebmusic-0.1
)

add_library(webmusic SHARED ${VALA_C_LIB_WEBMUSIC_COMMON})
target_link_libraries(webmusic ${GLIB_LDFLAGS})
set_target_properties(webmusic PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS webmusic DESTINATION "${CMAKE_INSTALL_FULL_LIBDIR}")


add_custom_command(OUTPUT libwebmusic-0.1.typelib
    COMMAND ${GIR_COMPILER}
       --shared-library=libwebmusic.so
        --output=${CMAKE_CURRENT_BINARY_DIR}/libwebmusic-0.1.typelib
        ${CMAKE_CURRENT_BINARY_DIR}/libwebmusic-0.1.gir
    DEPENDS webmusic)

add_custom_target(libwebmusic-typelib ALL DEPENDS libwebmusic-0.1.typelib)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libwebmusic-0.1.typelib
    DESTINATION "${CMAKE_INSTALL_FULL_LIBDIR}/girepository-1.0")

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libwebmusic-0.1.gir
    DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/gir-1.0")

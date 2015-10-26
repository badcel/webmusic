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
    libwebmusiccommon
)

add_library(webmusiccommon SHARED ${VALA_C_LIB_WEBMUSIC_COMMON})
target_link_libraries(webmusiccommon ${GLIB_LDFLAGS})
set_target_properties(webmusiccommon PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${COMMON_CFLAGS}")
install(TARGETS webmusiccommon DESTINATION "${PKG_LIBDIR}")

vala_precompile(VALA_C_LIB_SEARCH_PROVIDER
    LibSearchProvider.vala
OPTIONS
    ${VALAFLAGS}
PACKAGES
    glib-2.0
    gio-2.0
CUSTOM_VAPIS
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
    ${CMAKE_BINARY_DIR}/src/Lib/libwebmusiccommon.vapi
GENERATE_VAPI
    libsearchprovider
GENERATE_HEADER
    libsearchprovider
GENERATE_GIR
    libsearchprovider-0.1
)

add_library(searchprovider SHARED ${VALA_C_LIB_SEARCH_PROVIDER})
target_link_libraries(searchprovider webmusiccommon ${GLIB_LDFLAGS})
set_target_properties(searchprovider PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/src/Lib")
install(TARGETS searchprovider DESTINATION "${PKG_LIBDIR}")

add_custom_command(OUTPUT libsearchprovider-0.1.typelib
    COMMAND ${GIR_COMPILER}
       --shared-library=libsearchprovider.so
        --output=${CMAKE_CURRENT_BINARY_DIR}/libsearchprovider-0.1.typelib
        ${CMAKE_CURRENT_BINARY_DIR}/libsearchprovider-0.1.gir
    DEPENDS searchprovider)

add_custom_target(libsearchprovider-typelib ALL DEPENDS libsearchprovider-0.1.typelib)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libsearchprovider-0.1.typelib
    DESTINATION "${PKG_LIBDIR}/girepository-1.0")

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libsearchprovider-0.1.gir
    DESTINATION "${PKG_DATADIR}/gir-1.0")

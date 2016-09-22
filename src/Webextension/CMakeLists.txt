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

vala_precompile(VALA_C
    FileCache.vala
    Player.vala
    WebMusicWebExtension.vala
    JsApi.vala
    JavascriptMusicPlayer.vala
    JsInterface/JsConverter.vala
    JsInterface/JsObject.vala
OPTIONS
    ${VALAFLAGS}
PACKAGES
    glib-2.0
    gtk+-3.0
    json-glib-1.0
    WebKit2WebExtension-4.0
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/src/Lib/libwebmusic.vapi
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
    ${CMAKE_SOURCE_DIR}/vapi/javascriptcore.vapi
GENERATE_VAPI
    libwebextension
GENERATE_HEADER
    libwebextension
)

add_library(webextension SHARED ${VALA_C})
target_link_libraries(webextension webmusic ${GLIB_LDFLAGS} ${JSONGLIB_LDFLAGS} ${WEBEXTENSION_LDFLAGS})
set_target_properties(webextension PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${GTK_CFLAGS} ${JSONGLIB_CFLAGS} ${WEBEXTENSION_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/src/Lib")

install(TARGETS webextension DESTINATION "${PKG_LIBDIR}")

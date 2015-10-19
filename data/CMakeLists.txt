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

gsettings(${CMAKE_CURRENT_SOURCE_DIR} ${GSETTINGS_INSTALL_DIR})

install(FILES "about.ini"
        DESTINATION ${PKG_DATADIR})

if(MAKE_LOCAL_INSTALL)
    set(WEBMUSIC_DESKTOP_DIR "$ENV{HOME}/.local/share/applications")
    set(WEBMUSIC_LOCAL_BINDIR "${CMAKE_INSTALL_FULL_BINDIR}/")
else()
    set(WEBMUSIC_DESKTOP_DIR "${CMAKE_INSTALL_FULL_DATADIR}/applications")
    set(WEBMUSIC_LOCAL_BINDIR "")
endif()
webmusic_configure(FILES desktop webmusic.desktop ${WEBMUSIC_DESKTOP_DIR})

install(DIRECTORY icons/hicolor DESTINATION "${CMAKE_INSTALL_FULL_DATADIR}/icons")

find_program(GTK_UPDATE_ICON_CACHE gtk-update-icon-cache)
if(GTK_UPDATE_ICON_CACHE AND NOT MAKE_LOCAL_INSTALL)
    install(CODE "
        execute_process(COMMAND ${GTK_UPDATE_ICON_CACHE} -f
            \"\${CMAKE_INSTALL_FULL_DATADIR}/icons/hicolor\")
")
endif()

if(SHELL_SEARCH_PROVIDER)

    set(WEBMUSIC_DBUS_SERVICE_DIR "${CMAKE_INSTALL_FULL_DATADIR}/dbus-1/services")
    webmusic_configure(FILES desktop org.WebMusic.SearchProvider.service ${WEBMUSIC_DBUS_SERVICE_DIR})

    webmusic_gresource(org.WebMusic.SearchProvider.data.gresource ${JS_PKG_DATADIR})

    set(WEBMUSIC_SEARCHPROVIDER_DIR "${CMAKE_INSTALL_FULL_DATADIR}/gnome-shell/search-providers")
    install(FILES org.WebMusic.SearchProvider.search-provider.ini
            DESTINATION "${WEBMUSIC_SEARCHPROVIDER_DIR}")

endif()

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

gresource(${CMAKE_SOURCE_DIR}/src/Resources/ webmusic.gresource.xml
          ${CMAKE_BINARY_DIR}/src/Browser/ RESOURCE_FILE)

vala_precompile(VALA_C
    Browser.vala
    AppWindow.vala
    WebMusic.vala
    Dialogs/PreferencesDialog.vala
    Dialogs/ClearDataDialog.vala
    Dialogs/AboutDialog.vala
    Dialogs/ErrorDialog.vala
    Widgets/Osd/CoverStage.vala
    Widgets/Osd/ControlsActor.vala
    Widgets/Ui/RepeatButton.vala
    Plugins/IPlugin.vala
    Plugins/MPRIS.vala
    Plugins/Notification.vala
OPTIONS
    ${VALAFLAGS}
PACKAGES
    glib-2.0
    gtk+-3.0
    WebKit2-4.0
    clutter-gtk-1.0
    libnotify
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/src/Lib/libwebmusic.vapi
    ${CMAKE_SOURCE_DIR}/vapi/config.vapi
    ${CMAKE_SOURCE_DIR}/vapi/WebKitVersion.vapi
)

add_executable(webmusic-bin ${VALA_C} ${RESOURCE_FILE})
target_link_libraries(webmusic-bin webmusic ${GLIB_LDFLAGS} ${WEBKIT_LDFLAGS} ${CLUTTERGTK_LDFLAGS} ${NOTIFY_LDFLAGS})
set_target_properties(webmusic-bin PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${GTK_CFLAGS} ${WEBKIT_CFLAGS} ${CLUTTERGTK_CFLAGS} ${NOTIFY_CFLAGS} ${COMMON_CFLAGS}"
                      INCLUDE_DIRECTORIES "${CMAKE_BINARY_DIR}/src/Lib"
                      OUTPUT_NAME webmusic)

install(TARGETS webmusic-bin DESTINATION bin)

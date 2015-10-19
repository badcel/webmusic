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

project(WebMusic C)
cmake_minimum_required(VERSION 2.8)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(FindVala)
include(UseVala)
include(WebMusic)
include(FindGettext)
include(GNUInstallDirs)
include(GResource)
include(GSettings)

find_package(PkgConfig  0.28 REQUIRED)
find_package(Vala       0.24 REQUIRED)

webmusic_check_modules(GTK          REQUIRED gtk+-3.0>=3.12)
webmusic_check_modules(NOTIFY       REQUIRED libnotify>=0.7)
webmusic_check_modules(WEBEXTENSION REQUIRED webkit2gtk-web-extension-4.0>=2.6 )
webmusic_check_modules(WEBKIT       REQUIRED webkit2gtk-4.0>=2.6)
webmusic_check_modules(GLIB         REQUIRED glib-2.0>=2.40)
webmusic_check_modules(CLUTTERGTK   REQUIRED clutter-gtk-1.0>=1.5)
webmusic_check_modules(INTROSPECTON REQUIRED gobject-introspection-1.0>=1.40)
webmusic_check_modules(GJS          REQUIRED gjs-1.0>=1.43)

webmusic_find_program(INTLTOOL_MERGE intltool-merge)
webmusic_find_program(GLIB_COMPILE_RESOURCES glib-compile-resources)
webmusic_find_program(GLIB_COMPILE_SCHEMAS glib-compile-schemas)
webmusic_find_program(GIR_COMPILER g-ir-compiler)
webmusic_find_program(GJS gjs)

option(MAKE_LOCAL_INSTALL  "Allow to install in an arbitary location" OFF)
option(SHELL_SEARCH_PROVIDER "Creates the gnome-shell search-provider" ON)

set(PACKAGE "webmusic")
set(PACKAGE_NAME "org.WebMusic")
set(PACKAGE_VERSION 0.1)

set(PKG_DATADIR "${CMAKE_INSTALL_FULL_DATADIR}/${PACKAGE}")
set(PKG_LIBDIR "${CMAKE_INSTALL_FULL_LIBDIR}/${PACKAGE}")
set(GETTEXT_PACKAGE "${PACKAGE}")

set(JS_PACKAGE_NAME "org.WebMusic.SearchProvider")
set(JS_PKG_DATADIR "${CMAKE_INSTALL_FULL_DATADIR}/${JS_PACKAGE_NAME}")
set(JS_PKG_LIBDIR "${CMAKE_INSTALL_FULL_LIBDIR}/${JS_PACKAGE_NAME}")

set(COMMON_CFLAGS "-w")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPACKAGE=\\\"${PACKAGE}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPACKAGE_NAME=\\\"${PACKAGE_NAME}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPACKAGE_VERSION=\\\"${PACKAGE_VERSION}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPKG_DATA_DIR=\\\"${PKG_DATADIR}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DPKG_LIB_DIR=\\\"${PKG_LIBDIR}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DGETTEXT_PACKAGE=\\\"${GETTEXT_PACKAGE}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DLOCALE_DIR=\\\"${CMAKE_INSTALL_FULL_LOCALEDIR}\\\"")
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DTHEME_DIR=\\\"${CMAKE_INSTALL_FULL_DATADIR}/icons\\\"")

set(GSETTINGS_INSTALL_DIR "${CMAKE_INSTALL_FULL_DATADIR}/glib-2.0/schemas")

set(VALAFLAGS ${VALAFLAGS} --target-glib=2.38)
set(VALAFLAGS ${VALAFLAGS} --gresources=${CMAKE_SOURCE_DIR}/src/Resources/webmusic.gresource.xml)

message(STATUS "THIS COMPILES ${PACKAGE} VERSION ${PACKAGE_VERSION}")

if(MAKE_LOCAL_INSTALL)
    message(STATUS "[OPTION] LOCAL INSTALL IS ENABLED")
    set(CMAKE_INSTALL_RPATH "${PKG_LIBDIR}")
    file(MAKE_DIRECTORY "${GSETTINGS_INSTALL_DIR}")
endif()

if(SHELL_SEARCH_PROVIDER)
    message(STATUS "[OPTION] SHELL SEARCH PROVIDER IS ENABLED")
else()
    message(STATUS "[OPTION] SHELL SEARCH PROVIDER IS DISABLED")
endif()

add_subdirectory(src)
add_subdirectory(po)
add_subdirectory(man)
add_subdirectory(data)

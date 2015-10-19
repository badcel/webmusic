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

macro(webmusic_check_modules)
  pkg_check_modules(${ARGV})

  string(REPLACE ";" " " WEBMUSIC_STRIPPED "${${ARGV0}_CFLAGS}")
  set(${ARGV0}_CFLAGS "${WEBMUSIC_STRIPPED}")

  # Same with _LDFLAGS
  string(REPLACE ";" " " WEBMUSIC_STRIPPED "${${ARGV0}_LDFLAGS}")
  set(${ARGV0}_LDFLAGS "${WEBMUSIC_STRIPPED}")
endmacro()

function(webmusic_configure TYPE STYLE OUTPUT DESTINATION)
    configure_file(${OUTPUT}.in ${OUTPUT}.vars @ONLY)
    add_custom_target(${OUTPUT} ALL
                    ${INTLTOOL_MERGE}
                        --${STYLE}-style -u -q
                        ${CMAKE_SOURCE_DIR}/po
                        ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}.vars
                        ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT})
  install(${TYPE} ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT} DESTINATION ${DESTINATION})
endfunction()

function(webmusic_find_program VAR PROGRAM)
    _pkgconfig_invoke("glib-2.0" GLIB2 PREFIX "" "--variable=prefix")
    find_program(${VAR}
             NAMES ${PROGRAM}
             HINTS ${GLIB2_PREFIX})
             
    if(NOT ${VAR})
        message(FATAL_ERROR "Could not find ${PROGRAM}")
    endif()
endfunction()

function(webmusic_gresource OUTPUT DESTINATION)

    add_custom_target(${OUTPUT} ALL
        ${GLIB_COMPILE_RESOURCES}
            --sourcedir=${CMAKE_CURRENT_SOURCE_DIR}
            --target=${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT}
            ${CMAKE_CURRENT_SOURCE_DIR}/${OUTPUT}.xml)

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT} DESTINATION ${DESTINATION})
endfunction()

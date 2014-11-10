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

if(GETTEXT_FOUND)
    message(STATUS "gettext found")
else()
    message(STATUS "gettext not found")
endif()

file(GLOB POFILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.po")

foreach(FILE ${POFILES})
    string(REPLACE ".po" "" LINGUA ${FILE})
    GETTEXT_PROCESS_PO_FILES(${LINGUA} ALL PO_FILES ${LINGUA}.po)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}.gmo"
            DESTINATION "${CMAKE_INSTALL_FULL_LOCALEDIR}/${LINGUA}/LC_MESSAGES"
            RENAME "${GETTEXT_PACKAGE}.mo")
    list(APPEND LINGUA_TARGETS "${CMAKE_CURRENT_BINARY_DIR}/${LINGUA}.gmo")
endforeach ()
add_custom_target(translations ALL DEPENDS ${LINGUA_TARGETS})

find_program(INTLTOOL_UPDATE intltool-update)
if(INTLTOOL_UPDATE)

    add_custom_target(${GETTEXT_PACKAGE}.pot
        COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && ${INTLTOOL_UPDATE} --pot --gettext-package=${GETTEXT_PACKAGE})

    foreach(FILE ${POFILES})
        string(REPLACE ".po" "" LINGUA ${FILE})
        add_custom_command(TARGET ${GETTEXT_PACKAGE}.pot POST_BUILD
            COMMAND cd ${CMAKE_CURRENT_SOURCE_DIR} && ${GETTEXT_MSGMERGE_EXECUTABLE} -U ${LINGUA}.po ${GETTEXT_PACKAGE}.pot)
    endforeach ()  
endif()

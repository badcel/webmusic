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

function (gsettings SCHEMA_DIR OUTPUT_DIR)            
    file(GLOB ALL_SCHEMA_FILES
        "${SCHEMA_DIR}/*.gschema.xml"
    )

    install(
            FILES
                ${ALL_SCHEMA_FILES}
            DESTINATION
                ${OUTPUT_DIR}
    )

    install(CODE "
        execute_process(
            COMMAND 
                ${GLIB_COMPILE_SCHEMAS} 
                ${GSETTINGS_INSTALL_DIR}
        )
    ")
endfunction ()

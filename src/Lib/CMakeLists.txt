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
    libshare
GENERATE_HEADER
    libshare
GENERATE_GIR
    libshare-0.1
)

add_library(share SHARED ${VALA_C})
target_link_libraries(share ${GLIB_LDFLAGS})
set_target_properties(share PROPERTIES
                      COMPILE_FLAGS "${GLIB_CFLAGS} ${COMMON_CFLAGS}")

install(TARGETS share DESTINATION "${PKG_LIBDIR}")

#add_custom_command(OUTPUT libshare-0.1.gir
#                   COMMAND ${GIR_COMPILER}  
#                        --shared-library=libshare.so 
#                        --output=${CMAKE_CURRENT_BINARY_DIR}/libshare-0.1.typelib
#                        ${CMAKE_CURRENT_BINARY_DIR}/libshare-0.1.gir
#                   DEPENDS share)

#add_custom_target(gi ALL DEPENDS libshare-0.1.gir)

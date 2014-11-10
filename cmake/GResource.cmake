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

function (gresource resource_dir resource_file output_dir output_source)
    # Get the output file path
    set (output_c "${output_dir}/Resources.c")
    set (${output_source} ${output_c} PARENT_SCOPE)

    # Command to compile the resources
    add_custom_command (
        OUTPUT ${output_c}
        WORKING_DIRECTORY ${resource_dir}
        COMMAND ${GLIB_COMPILE_RESOURCES} --generate-source --target=${output_c} ${resource_file}
    )
endfunction ()

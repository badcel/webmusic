 #
 #   Copyright (C) 2018  Marcel Tiede
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

help2man = find_program('help2man', required: false)
if help2man.found()
  help2man_opts = [
    '--no-info'
  ]

  custom_target('webmusic.1',
    output: 'webmusic.1',
    command: [
      help2man, help2man_opts, '--output=@OUTPUT@', webmusic],
    install: true,
    install_dir: join_paths(datadir, 'man/man1')
  )
endif

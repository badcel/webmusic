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

libwebmusic_vala_sources = files(
  'Api.vala',
  'Directory.vala',
  'FileCache.vala',
  'Namespace.vala',
  'PlayerApi.vala',
  'PlaylistApi.vala',
  'PluginManager.vala',
  'Service.vala',
  'VariantHelper.vala'
)

libwebmusic_c_args = [
  '-include', 'config.h',
  '-DLOCALEDIR="@0@"'.format(locale_dir)
]

libwebmusic_deps = [
  glib,
  gobject,
  libpeas
]

libwebmusic_sources = [
  libwebmusic_vala_sources
]

libwebmusic_gir = 'libwebmusic-0.1.gir'

libwebmusic = library('webmusic-0.1', libwebmusic_sources,
  include_directories: config_h_dir,
  vala_args: vala_args,
  vala_header: 'libwebmusic.h',
  vala_vapi: 'libwebmusic-0.1.vapi',
  vala_gir: libwebmusic_gir,
  c_args: libwebmusic_c_args,
  dependencies: libwebmusic_deps,
  install: true,
  install_dir: [pkglibdir, false, false, true],
)

if g_ir_compiler.found()
  custom_target('webmusic-typelib',
    command: [g_ir_compiler,
      '--shared-library', libwebmusic.full_path(),
      '--output', '@OUTPUT@',
      join_paths(meson.current_build_dir(), libwebmusic_gir)],
    output: 'libwebmusic-0.1.typelib',
    depends: libwebmusic,
    install_dir: typelibdir,
    install: true
  )
endif

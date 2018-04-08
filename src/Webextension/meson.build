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

webextension_vala_sources = files(
  'DBusApi.vala',
  'IApiAdapter.vala',
  'JsAdapter.vala',
  'JsInterface/JsConverter.vala',
  'JsInterface/JsObject.vala',
  'WebMusicWebExtension.vala'
)

webextension_c_args = [
  '-include', 'config.h',
  '-DLOCALEDIR="@0@"'.format(locale_dir),
]

webextension_deps = [
  glib,
  gtk,
  json_glib,
  webkit2gtk_web_extension,
]

webextension_sources = [
  webextension_vala_sources
]

webextension_args = vala_args
webextension_args += ['--pkg', 'javascriptcore']

library('webextension', webextension_sources,
  include_directories: [config_h_dir, libwebmusic_h_dir],
  vala_args: webextension_args,
  c_args: webextension_c_args,
  dependencies: webextension_deps,
  link_with: libwebmusic,
  install: true,
  install_dir: pkglibdir,
  install_rpath: pkglibdir
)

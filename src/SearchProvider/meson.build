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

searchprovider_config = configuration_data()
searchprovider_config.set_quoted('PACKAGE_VERSION', meson.project_version())
searchprovider_config.set_quoted('PREFIX', webmusic_prefix)
searchprovider_config.set_quoted('LIBDIR', libdir)
searchprovider_config.set('GJS', gjs_console)

configure_file(
  input: 'org.WebMusic.SearchProvider.in',
  output: 'org.WebMusic.SearchProvider',
  configuration: searchprovider_config,
  install: true,
  install_dir: pkgdatadirsp
)

searchprovider_src_resources = gnome.compile_resources(
  'org.WebMusic.SearchProvider.src',
  'org.WebMusic.SearchProvider.src.gresource.xml',
  source_dir: '.',
  gresource_bundle: true,
  install: true,
  install_dir: pkgdatadirsp
)

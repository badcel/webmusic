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

install_subdir('Resources/Services/',
  install_dir: pkgdatadir,
  exclude_files: 'Resources/Services/example/example.ini.in'
)

resources_config = configuration_data()
resources_config.set('PKG_DATADIR', pkgdatadir)

configure_file(
  input: 'Resources/Services/example/example.ini.in',
  output: 'example.ini',
  configuration: resources_config,
  install: true,
  install_dir: join_paths(pkgdatadir, 'Services', 'example'),
)

browser_resource_files = files('Resources/webmusic.gresource.xml')
browser_resources = gnome.compile_resources(
  'org.WebMusic.Browser',
  browser_resource_files,
  source_dir: 'Resources',
  c_name: 'resources'
)

subdir('Lib')
subdir('Browser')
subdir('Webextension')
subdir('Plugins')

if searchprovider_enabled
  subdir('SearchProvider')
endif
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

compiled = gnome.compile_schemas()
install_data('org.WebMusic.gschema.xml',
  install_dir: join_paths(datadir, 'glib-2.0', 'schemas')
)

install_data('about.ini',
  install_dir: pkgdatadir
)

i18n.merge_file(
  input: 'org.WebMusic.desktop.in',
  output: 'org.WebMusic.desktop',
  type: 'desktop',
  po_dir: po_dir,
  install: true,
  install_dir: join_paths(datadir, 'applications')
)

service_config = configuration_data()
service_config.set('bindir', bindir)
service_config.set('PACKAGE', meson.project_name())
service_config.set('PACKAGE_NAME', app_id)
service_config.set('JS_PKG_DATADIR', pkgdatadirsp)
service_config.set('JS_PACKAGE_NAME', searchprovider_app_id)

configure_file(
  input: 'org.WebMusic.service.in',
  output: 'org.WebMusic.service',
  configuration: service_config,
  install: true,
  install_dir: join_paths(datadir, 'dbus-1', 'services')
)

iconsdir = join_paths(datadir, 'icons', 'hicolor')
foreach size: ['48x48', '256x256', 'scalable']
  install_subdir('icons/hicolor/' + size, install_dir: iconsdir)
endforeach

if searchprovider_enabled

  configure_file(
    input: 'org.WebMusic.SearchProvider.service.in',
    output: 'org.WebMusic.SearchProvider.service',
    configuration: service_config,
    install: true,
    install_dir: join_paths(datadir, 'dbus-1', 'services')
  )

  searchprovider_data_resources = gnome.compile_resources(
    'org.WebMusic.SearchProvider.data',
    'org.WebMusic.SearchProvider.data.gresource.xml',
    source_dir: '.',
    gresource_bundle: true,
    install: true,
    install_dir: pkgdatadirsp
  )

  install_data('org.WebMusic.SearchProvider.search-provider.ini',
    install_dir: join_paths(datadir, 'gnome-shell', 'search-providers')
  )

endif
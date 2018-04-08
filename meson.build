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

project('webmusic', ['c', 'vala'],
  version: '0.1',
  license: 'GPL3+',
  meson_version: '>= 0.45',
)

app_id = 'org.WebMusic'
searchprovider_app_id = app_id + '.SearchProvider'

gnome = import('gnome')
i18n = import('i18n')

g_ir_compiler = find_program('g-ir-compiler')

add_project_arguments(
  ['--vapidir', join_paths(meson.source_root(), 'vapi')],
  language: 'vala'
)

# Options
searchprovider_enabled = get_option('searchprovider')
plugin_notification_enabled = get_option('plugin_notification')
manpage_enabled = get_option('manpage')

# Common variables
config_h_dir = include_directories('.')
libwebmusic_h_dir = include_directories('src/Lib')

webmusic_prefix = get_option('prefix')

datadir = join_paths(webmusic_prefix, get_option('datadir'))
bindir = join_paths(webmusic_prefix, get_option('bindir'))
libdir = join_paths(webmusic_prefix, get_option('libdir'))

icon_dir = join_paths(datadir, 'icons')
locale_dir = join_paths(webmusic_prefix, get_option('localedir'))
po_dir = join_paths(meson.source_root(), 'po')

pkgdatadir = join_paths(datadir, meson.project_name())
pkglibdir = join_paths(libdir, meson.project_name())

girdir = join_paths(datadir, 'gir-1.0')
typelibdir = join_paths(libdir, 'girepository-1.0')

pkgdatadirplugins = join_paths(pkgdatadir, 'plugins')
pkglibdirplugins = join_paths(pkglibdir, 'plugins')

pkgdatadirsp = join_paths(datadir, searchprovider_app_id)
pkglibdirsp = join_paths(libdir, searchprovider_app_id)

# Dependencies
min_glib_version = '2.40'

glib = dependency('glib-2.0', version: '>=' + min_glib_version)
gobject = dependency('gobject-2.0')
gobject_introspection = dependency('gobject-introspection-1.0', version: '>=1.40')
gtk = dependency('gtk+-3.0', version: '>= 3.12.0')
json_glib = dependency('json-glib-1.0', version: '>=1.2')
libnotify = dependency('libnotify', version: '>=0.7')
libpeas = dependency('libpeas-1.0', version: '>=1.2')
webkit2gtk = dependency('webkit2gtk-4.0', version: '>=2.6')
webkit2gtk_web_extension = dependency('webkit2gtk-web-extension-4.0', version: '>=2.6')

if searchprovider_enabled
  gjs = dependency('gjs-1.0', version: '>=1.43')
  gjs_console = gjs.get_pkgconfig_variable('gjs_console')
endif

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALE_DIR', locale_dir)
conf.set_quoted('THEME_DIR', icon_dir)
conf.set_quoted('PACKAGE', meson.project_name())
conf.set_quoted('PACKAGE_NAME', app_id)
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('PKG_DATA_DIR', pkgdatadir)
conf.set_quoted('PKG_DATA_DIR_PLUGINS', pkgdatadirplugins)
conf.set_quoted('PKG_LIB_DIR', pkglibdir)
conf.set_quoted('PKG_LIB_DIR_PLUGINS', pkglibdirplugins)
configure_file(output: 'config.h', configuration: conf)

vala_args = [
  '--target-glib=@0@'.format(min_glib_version),
  '--pkg', 'config'
]

# Post-install scripts
meson.add_install_script('meson_post_install.py')

subdir('data')
subdir('po')
subdir('src')

if manpage_enabled
  subdir('man')
endif

output = '\n        ' + meson.project_name() + ' ' + meson.project_version() + '\n'
output += '        ======================\n\n'
output += '        prefix:                    ' + webmusic_prefix + '\n'
output += '        build searchprovider:      ' + '@0@'.format(searchprovider_enabled) + '\n'
output += '        build plugin notification: ' + '@0@'.format(plugin_notification_enabled) + '\n'
output += '        build manpages:            ' + '@0@'.format(manpage_enabled) + '\n'

if searchprovider_enabled and not g_ir_compiler.found()
  output += '        WARNING: gir compiler not found searchprovider will not work!'
endif

output += '\n'
message(output)
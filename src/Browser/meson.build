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

browser_vala_sources = files(
  'Browser.vala',
  'AppWindow.vala',
  'WebMusic.vala',
  'Dialogs/PreferencesDialog.vala',
  'Dialogs/ClearDataDialog.vala',
  'Dialogs/AboutDialog.vala',
  'Dialogs/ErrorDialog.vala',
  'Plugins/IPlugin.vala',
  'Plugins/MPRIS.vala',
  'Plugins/MiniWidget.vala',
  'Widgets/ImageOverlay.vala',
  'Widgets/OsdToolbar.vala',
  'Widgets/RepeatButton.vala'
)

browser_c_args = [
  '-include', 'config.h',
  '-DLOCALEDIR="@0@"'.format(locale_dir)
]

browser_deps = [
  glib,
  gtk,
  webkit2gtk
]

browser_sources = [
  browser_vala_sources,
  browser_resources
]

brwoser_args = vala_args
brwoser_args += ['--pkg', 'WebKitVersion']

webmusic = executable('webmusic', browser_sources,
  include_directories: [config_h_dir, libwebmusic_h_dir],
  vala_args: brwoser_args,
  c_args: browser_c_args,
  dependencies: browser_deps,
  link_with: libwebmusic,
  install_rpath: pkglibdir,
  install: true
)
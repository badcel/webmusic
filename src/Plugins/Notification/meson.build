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

plugin_notification_vala_sources = files(
  'Notification.vala'
)

plugin_notification_c_args = [
  '-include', 'config.h',
  '-DLOCALEDIR="@0@"'.format(locale_dir)
]

plugin_notification_deps = [
  glib,
  libnotify,
  libpeas
]

plugin_notification_sources = [
  plugin_notification_vala_sources
]

pkglibdirpluginsnotification = join_paths(pkglibdirplugins, 'notification')

libwebmusic = library('notification', plugin_notification_sources,
  include_directories: [config_h_dir, libwebmusic_h_dir],
  vala_args: vala_args,
  c_args: plugin_notification_c_args,
  dependencies: plugin_notification_deps,
  link_with: libwebmusic,
  install: true,
  install_dir: pkglibdirpluginsnotification
)

install_data('notification.plugin',
  install_dir: pkglibdirpluginsnotification
)

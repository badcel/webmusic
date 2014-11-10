pkgname=WebMusic
pkgver=0.1
pkgrel=1
pkgdesc="A web based music player that integrates your favourite music service into the desktop"
arch=(i686 x86_64)
url="http://webmusic.tiede.org"
license=(GPL3)
depends=(libnotify webkitgtk dconf clutter-gtk)
makedepends=(cmake vala intltool)

source=(WebMusic.tar.gz)
md5sums=('1f714b88cec80ed38f770e95708a16d8')

build() {
  cd "$srcdir/$pkgname"

  cmake . -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_INSTALL_SYSCONFDIR=/etc \
          -DCMAKE_INSTALL_LIBDIR=/usr/lib \
          -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib/$pkgname
  make
}

package() {
  cd "$srcdir/$pkgname"

  make DESTDIR="$pkgdir/" install
}


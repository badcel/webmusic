pkgname=webmusic
pkgver=0.1
pkgrel=2
pkgdesc="A web based music player that integrates your favourite music service into the desktop"
arch=(i686 x86_64)
url="http://webmusic.tiede.org"
license=(GPL3)
depends=(gtk3 libnotify webkit2gtk dconf libpeas json-glib)
makedepends=(meson vala intltool)

#source=(https://github.com/badcel/webmusic/archive/webmusic-${pkgver}.tar.gz)
sha256sums=('SKIP')
prepare() {
  cd $pkgname
}

build() {
  arch-meson $pkgname build
  ninja -C build
}

package() {
  DESTDIR="$pkgdir" ninja -C build install
}


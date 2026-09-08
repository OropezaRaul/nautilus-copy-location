# Maintainer: Omarchy local build — nautilus with "Copy Location" fixed to copy the
# plain-text path instead of a file-transfer clipboard.
# Based on the official Arch Linux PKGBUILD (gitlab.archlinux.org/archlinux/packaging/packages/nautilus).
# Patch: nautilus-copy-location-text.patch

pkgbase=nautilus
pkgname=(
  nautilus
  libnautilus-extension
  libnautilus-extension-docs
)
pkgver=50.2.2
pkgrel=1
pkgdesc="Default file manager for GNOME (Omarchy patch: Copy Location copies plain-text path)"
url="https://apps.gnome.org/Nautilus/"
arch=(x86_64)
license=(GPL-3.0-or-later)
depends=(
  cairo
  dconf
  gdk-pixbuf2
  gexiv2
  glib2
  glibc
  glycin
  glycin-gtk4
  gnome-autoar
  gnome-desktop-4
  graphene
  gst-plugins-base-libs
  gstreamer
  gtk4
  gvfs
  hicolor-icon-theme
  icu
  libadwaita
  libcloudproviders
  libgcc
  libportal
  libportal-gtk4
  libx11
  localsearch
  pango
  tinysparql
  wayland
  xdg-user-dirs-gtk
)
makedepends=(
  appstream
  blueprint-compiler
  gi-docgen
  git
  glib2-devel
  gobject-introspection
  meson
)
checkdepends=(
  python-gobject
)
source=(
  nautilus-50.2.2.tar.gz
  nautilus-copy-location-text.patch
)
sha256sums=(
  '8e76a2aeff884ce4412092b7c04d68d119b8934c1d81b76e1497d41c7f0ef1b8'
  '6167b111d77374d5b2c6edf0eaf4db35d76905ff61a75539f024223b95e7d9e1'
)

prepare() {
  cd nautilus-50.2.2
  patch -Np1 -i ../nautilus-copy-location-text.patch
}

build() {
  local meson_options=(
    --prefix /usr
    --sysconfdir /etc
    --sbindir /usr/bin
    --bindir /usr/bin
    --libdir /usr/lib
    --libexecdir /usr/lib
    --datadir /usr/share
    --includedir /usr/include
    --buildtype plain
    --auto-features enabled
    -D docs=true
    -D packagekit=false
    -D selinux=false
  )

  meson setup nautilus-50.2.2 build "${meson_options[@]}"
  meson compile -C build
}

_pick() {
  local p="$1" f d; shift
  for f; do
    d="$srcdir/$p/${f#$pkgdir/}"
    mkdir -p "$(dirname "$d")"
    mv "$f" "$d"
    rmdir -p --ignore-fail-on-non-empty "$(dirname "$f")"
  done
}

package_nautilus() {
  depends+=(libnautilus-extension.so)
  groups=(gnome)

  meson install -C build --destdir "$pkgdir"

  cd "$pkgdir"

  _pick libne usr/include
  _pick libne usr/lib/{girepository-1.0,libnautilus-extension*,pkgconfig}
  _pick libne usr/share/gir-1.0

  _pick ldocs usr/share/doc
}

package_libnautilus-extension() {
  pkgdesc="Extension interface for Nautilus"
  depends=(
    glib2
    glibc
    libgcc
  )
  provides=(libnautilus-extension.so)

  mv libne/* "$pkgdir"
}

package_libnautilus-extension-docs() {
  pkgdesc="Extension interface for Nautilus (documentation)"
  depends=()

  mv ldocs/* "$pkgdir"
}

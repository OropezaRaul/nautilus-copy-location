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
pkgver=50.3.1
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
  nautilus-50.3.1.tar.xz
  nautilus-copy-location-text.patch
)
sha256sums=(
  '71d54703cc6095db829baa13ad9d853d18b49cb84cae3e0b927ed6f3cf679a1f'
  'b9f3a0de0ee90c2b2bdd4dd42e649824274090b452122177ce9ac795ff986245'
)

prepare() {
  cd nautilus-50.3.1
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

  meson setup nautilus-50.3.1 build "${meson_options[@]}"
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

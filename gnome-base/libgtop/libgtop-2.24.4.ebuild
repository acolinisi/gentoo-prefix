# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/libgtop/libgtop-2.24.4.ebuild,v 1.10 2009/04/28 11:27:28 armin76 Exp $

inherit gnome2 eutils autotools

DESCRIPTION="A library that provides top functionality to applications"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="~amd64-linux ~x86-linux ~x64-solaris"
IUSE="debug"

RDEPEND=">=dev-libs/glib-2.6"
DEPEND="${RDEPEND}
		dev-util/pkgconfig
		>=dev-util/intltool-0.35"

DOCS="AUTHORS ChangeLog NEWS README"

src_unpack() {
	gnome2_src_unpack
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-2.23.90-solaris.patch
	eautoreconf
}

pkg_setup() {
	G2CONF="${G2CONF} --disable-static"
}

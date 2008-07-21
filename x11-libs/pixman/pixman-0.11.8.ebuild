# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/pixman/pixman-0.11.8.ebuild,v 1.3 2008/07/20 14:01:57 yngwin Exp $

EAPI="prefix"

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular

DESCRIPTION="Low-level pixel manipulation routines"
KEYWORDS="~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="altivec mmx sse sse2"

CONFIGURE_OPTIONS="$(use_enable altivec vmx) $(use_enable mmx) \
$(use_enable sse2) --disable-gtk"

src_unpack() {
	x-modular_src_unpack
	cd "${S}"
	use sse && epatch "${FILESDIR}"/${P}-sse.patch
	epatch "${FILESDIR}"/${P}-sse2-intrinsics-check.patch
	eautoreconf
	elibtoolize
}

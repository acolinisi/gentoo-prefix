# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnustep-base/gnustep-back-cairo/gnustep-back-cairo-0.12.0.ebuild,v 1.1 2007/08/18 15:32:31 grobian Exp $

EAPI="prefix"

inherit gnustep-base

S=${WORKDIR}/gnustep-back-${PV}

DESCRIPTION="Cairo back-end component for the GNUstep GUI Library."

HOMEPAGE="http://www.gnustep.org"
SRC_URI="ftp://ftp.gnustep.org/pub/gnustep/core/gnustep-back-${PV}.tar.gz"
KEYWORDS="~amd64 ~x86 ~x86-solaris"
SLOT="0"
LICENSE="LGPL-2.1"

IUSE="opengl xim glitz"
DEPEND="${GNUSTEP_CORE_DEPEND}
	~gnustep-base/gnustep-gui-${PV}
	opengl? ( virtual/opengl virtual/glu )

	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXmu
	x11-libs/libXt
	x11-libs/libXft
	x11-libs/libXrender

	>=media-libs/freetype-2.1.9
	>=x11-libs/cairo-1.2.0
	!gnustep-base/gnustep-back-art
	!gnustep-base/gnustep-back-xlib"
RDEPEND="${DEPEND}"

src_compile() {
	egnustep_env

	use opengl && myconf="--enable-glx"
	myconf="$myconf $(use_enable xim)"
	myconf="$myconf --enable-server=x11"
	myconf="$myconf --enable-graphics=cairo"
	# Seems broken for now
	#myconf="$myconf $(use_enable glitz)"

	econf $myconf || die "configure failed"

	egnustep_make
}

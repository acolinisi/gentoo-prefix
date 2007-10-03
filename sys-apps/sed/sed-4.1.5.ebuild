# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/sed/sed-4.1.5.ebuild,v 1.19 2007/07/10 23:40:55 uberlord Exp $

EAPI="prefix"

inherit flag-o-matic

DESCRIPTION="Super-useful stream editor"
HOMEPAGE="http://sed.sourceforge.net/"
SRC_URI="mirror://gnu/sed/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~ppc-aix ~ppc-macos ~sparc-solaris ~x86 ~x86-fbsd ~x86-macos ~x86-solaris"
IUSE="nls static userland_GNU"

RDEPEND="nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

src_bootstrap_sed() {
	# make sure system-sed works #40786
	export NO_SYS_SED=""
	if ! type -p sed ; then
		NO_SYS_SED="!!!"
		./bootstrap.sh || die "couldnt bootstrap"
		cp sed/sed "${T}"/ || die "couldnt copy"
		export PATH="${PATH}:${T}"
		make clean || die "couldnt clean"
	fi
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-4.1.4-makeinfo-c-locale.patch
	epatch "${FILESDIR}"/${P}-alloca.patch
	epatch "${FILESDIR}"/${PN}-4.1.4-aix-malloc.patch
	# don't use sed here if we have to recover a broken host sed
}

src_compile() {
	src_bootstrap_sed
	# make sure all sed operations here are repeatable
	sed -i \
		-e '/docdir =/s:=.*/doc:= $(datadir)/doc/'${PF}'/html:' \
		doc/Makefile.in || die "sed html doc"

	local myconf= bindir="${EPREFIX}"/bin
	if ! use userland_GNU ; then
		myconf="--program-prefix=g"
		bindir="${EPREFIX}"/usr/bin
	fi
	use static && append-ldflags -static
	econf \
		--bindir="${bindir}" \
		$(use_enable nls) \
		${myconf} \
		|| die "Configure failed"
	emake || die "build failed"
}

src_install() {
	emake install DESTDIR="${D}" || die "Install failed"
	dodoc NEWS README* THANKS AUTHORS BUGS ChangeLog
	docinto examples
	dodoc "${FILESDIR}"/{dos2unix,unix2dos}

	rm -f "${ED}"/usr/lib/charset.alias "${ED}"/usr/share/locale/locale.alias
}

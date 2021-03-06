# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools multilib versionator flag-o-matic toolchain-funcs

DESCRIPTION="Ghostscript is an interpreter for the PostScript language and for PDF"
HOMEPAGE="http://ghostscript.com/"

# Maintainer notes about djvu support:
# gsdjvu has not seen any commits since July 2016, which was also roughly the time
# when ghostscript started rearranging internals. Issues I found so far:
# * gs_state and gs_imager_state got unified into gs_gstate
# * decode_glyph changed arguments and semantics (it doesnt give you the unicode now,
#   but the length of the required byte array, which you have to allocate and fill)
# * gs_text_enum_t has lost its element pis (???)

MY_P=${P/-gpl}
# GSDJVU_PV=1.9
PVM=$(get_version_component_range 1-2)
PVM_S=$(replace_all_version_separators "" ${PVM})
# SRC_URI="
#	https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${PVM_S}/${MY_P}.tar.xz
#	mirror://gentoo/${PN}-9.20-patchset-1.tar.xz
#	djvu? ( mirror://sourceforge/djvu/gsdjvu-${GSDJVU_PV}.tar.gz )"
SRC_URI="
	https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${PVM_S}/${MY_P}.tar.xz
	https://dev.gentoo.org/~dilfridge/distfiles/${PN}-9.20-patchset-2.tar.xz
"

LICENSE="AGPL-3 CPL-1.0"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
# IUSE="cups dbus djvu gtk l10n_de static-libs tiff unicode X"
IUSE="cups dbus gtk l10n_de static-libs tiff unicode X"
# RESTRICT="djvu? ( bindist )"

COMMON_DEPEND="
	app-text/libpaper
	media-libs/fontconfig
	>=media-libs/freetype-2.4.9:2=
	media-libs/jbig2dec
	>=media-libs/lcms-2.6:2
	>=media-libs/libpng-1.6.2:0=
	>=media-libs/openjpeg-2.1.0:2=
	>=sys-libs/zlib-1.2.7:=
	virtual/jpeg:0
	cups? ( >=net-print/cups-1.3.8 )
	dbus? ( sys-apps/dbus )
	gtk? ( || ( x11-libs/gtk+:3 x11-libs/gtk+:2 ) )
	unicode? ( net-dns/libidn )
	tiff? ( >=media-libs/tiff-4.0.1:0= )
	X? ( x11-libs/libXt x11-libs/libXext )
"
#	djvu? ( app-text/djvu )

DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig
"

RDEPEND="${COMMON_DEPEND}
	>=app-text/poppler-data-0.4.5-r1
	>=media-fonts/urw-fonts-2.4.9
	l10n_ja? ( media-fonts/kochi-substitute )
	l10n_ko? ( media-fonts/baekmuk-fonts )
	l10n_zh-CN? ( media-fonts/arphicfonts )
	l10n_zh-TW? ( media-fonts/arphicfonts )
	!!media-fonts/gnu-gs-fonts-std
	!!media-fonts/gnu-gs-fonts-other
	!<net-print/cups-filters-1.0.36-r2
"

S="${WORKDIR}/${MY_P}"

LANGS="ja ko zh-CN zh-TW"
for X in ${LANGS} ; do
	IUSE="${IUSE} l10n_${X}"
done

src_prepare() {
	default

	# remove internal copies of various libraries
	rm -rf "${S}"/cups/libs || die
	rm -rf "${S}"/expat || die
	rm -rf "${S}"/freetype || die
	rm -rf "${S}"/jbig2dec || die
	rm -rf "${S}"/jpeg{,xr} || die
	rm -rf "${S}"/lcms{,2} || die
	rm -rf "${S}"/libpng || die
	rm -rf "${S}"/tiff || die
	rm -rf "${S}"/zlib || die
	rm -rf "${S}"/openjpeg || die
	# remove internal CMaps (CMaps from poppler-data are used instead)
	rm -rf "${S}"/Resource/CMap || die

	# apply various patches, many borrowed from Fedora
	# http://pkgs.fedoraproject.org/cgit/ghostscript.git
	eapply "${WORKDIR}/patches/"*.patch

	eapply $FILESDIR/ghostscript-gpl-9.10-darwin.patch

#	if use djvu ; then
#		unpack gsdjvu-${GSDJVU_PV}.tar.gz
#
#		local gsdjvu_base=devices
#		local gsdjvu_msed='-e s/@@djvu@@/DEV/g'
#
#		cp gsdjvu-${GSDJVU_PV}/gdevdjvu.c "${S}"/${gsdjvu_base} || die
#
#		cp gsdjvu-${GSDJVU_PV}/ps2utf8.ps "${S}"/lib || die
#
#		cp gsdjvu-${GSDJVU_PV}/gsdjvu "${S}" || die
#		cp "${S}"/${gsdjvu_base}/contrib.mak "${S}"/${gsdjvu_base}/contrib.mak.gsdjvu || die
#		grep -q djvusep "${S}"/${gsdjvu_base}/contrib.mak || \
#			sed ${gsdjvu_msed} < gsdjvu-${GSDJVU_PV}/gsdjvu.mak >> "${S}"/${gsdjvu_base}/contrib.mak || die
#
##		# install ps2utf8.ps, bug #197818
##		sed -i -e '/$(EXTRA_INIT_FILES)/ a\ps2utf8.ps \\' \
##			"${S}"/base/unixinst.mak || die "sed failed"
#	fi

	if ! use gtk ; then
		sed -i -e "s:\$(GSSOX)::" \
			-e "s:.*\$(GSSOX_XENAME)$::" \
			"${S}"/base/unix-dll.mak || die "sed failed"
	fi

	# Force the include dirs to a neutral location.
	sed -i \
		-e "/^ZLIBDIR=/s:=.*:=${T}:" \
		configure.ac || die
	# Some files depend on zlib.h directly.  Redirect them. #573248
	# Also make sure to not define OPJ_STATIC to avoid linker errors due to
	# hidden symbols (https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=203327#c1)
	sed -i \
		-e '/^zlib_h/s:=.*:=:' \
		-e 's|-DOPJ_STATIC ||' \
		base/lib.mak || die

	# search path fix
	# put LDFLAGS after BINDIR, bug #383447
	sed -i -e "s:\$\(gsdatadir\)/lib:@datarootdir@/ghostscript/${PVM}/$(get_libdir):" \
		-e "s:exdir=.*:exdir=@datarootdir@/doc/${PF}/examples:" \
		-e "s:docdir=.*:docdir=@datarootdir@/doc/${PF}/html:" \
		-e "s:GS_DOCDIR=.*:GS_DOCDIR=@datarootdir@/doc/${PF}/html:" \
		-e 's:-L$(BINDIR):& $(LDFLAGS):g' \
		"${S}"/Makefile.in "${S}"/base/*.mak || die "sed failed"

	cd "${S}" || die
	# remove incorrect symlink, bug 590384
	rm -f ijs/ltmain.sh || die
	eautoreconf

	cd "${S}/ijs" || die
	eautoreconf
}

src_configure() {
	local FONTPATH
	for path in \
		"${EPREFIX}"/usr/share/fonts/urw-fonts \
		"${EPREFIX}"/usr/share/fonts/Type1 \
		"${EPREFIX}"/usr/share/fonts \
		"${EPREFIX}"/usr/share/poppler/cMap/Adobe-CNS1 \
		"${EPREFIX}"/usr/share/poppler/cMap/Adobe-GB1 \
		"${EPREFIX}"/usr/share/poppler/cMap/Adobe-Japan1 \
		"${EPREFIX}"/usr/share/poppler/cMap/Adobe-Japan2 \
		"${EPREFIX}"/usr/share/poppler/cMap/Adobe-Korea1
	do
		FONTPATH="$FONTPATH${FONTPATH:+:}$path"
	done

	PKGCONFIG=$(type -P $(tc-getPKG_CONFIG)) \
	econf \
		--enable-dynamic$(tc-is-static-only && echo =no) \
		--enable-freetype \
		--enable-fontconfig \
		--enable-openjpeg \
		--disable-compile-inits \
		--with-drivers=ALL \
		--with-fontpath="$FONTPATH" \
		--with-ijs \
		--with-jbig2dec \
		--with-libpaper \
		--without-luratech \
		$(use_enable cups) \
		$(use_enable dbus) \
		$(use_enable gtk) \
		$(use_with cups pdftoraster) \
		$(use_with unicode libidn) \
		$(use_with tiff system-libtiff) \
		$(use_with X x)

#	if use djvu ; then
#		sed -i -e 's!$(DD)bbox.dev!& $(DD)djvumask.dev $(DD)djvusep.dev!g' \
#			"${S}"/Makefile || die "sed failed"
#	fi

	cd "${S}/ijs" || die
	econf \
		--enable-shared$(tc-is-static-only && echo =no) \
		$(use_enable static-libs static)
}

src_compile() {
	tc-is-static-only || emake so
	emake all

	cd "${S}/ijs" || die
	emake
}

src_install() {
	tc-is-static-only || emake DESTDIR="${D}" install-so
	emake DESTDIR="${D}" install

#	use djvu && dobin gsdjvu

	# move gsc to gs, bug #343447
	# gsc collides with gambit, bug #253064
	mv -f "${ED}"/usr/bin/{gsc,gs} || die

	cd "${S}/ijs" || die
	emake DESTDIR="${D}" install

	# rename the original cidfmap to cidfmap.GS
	mv "${ED}/usr/share/ghostscript/${PVM}/Resource/Init/cidfmap"{,.GS} || die

	# install our own cidfmap to handle CJK fonts
	insinto /usr/share/ghostscript/${PVM}/Resource/Init
	doins \
		"${WORKDIR}/fontmaps/CIDFnmap" \
		"${WORKDIR}/fontmaps/cidfmap"
	for X in ${LANGS} ; do
		if use l10n_${X} ; then
			doins "${WORKDIR}/fontmaps/cidfmap.${X/-/_}"
		fi
	done

	# install the CMaps from poppler-data properly, bug #409361
	dosym "/usr/share/poppler/cMaps" "/usr/share/ghostscript/${PVM}/Resource/CMap"

	use static-libs || find "${ED}" -name '*.la' -delete

	# fix install_names
	if [[ ${CHOST} == *-darwin* ]] ; then
		local lib
		for lib in "${ED%/}"/usr/$(get_libdir)/*.dylib ; do
			install_name_tool -id "${lib#${D%/}}" "${lib}"
		done
		local libgs="libgs.${PV}.dylib"
		install_name_tool -change "${libgs}" @executable_path/../$(get_libdir)/"${libgs}" \
			"${ED}"/usr/bin/gs
	fi

	if ! use l10n_de; then
		rm -r "${ED}"/usr/share/man/de || die
	fi
}

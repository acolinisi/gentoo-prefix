# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/perl-core/Digest-SHA/Digest-SHA-5.47.ebuild,v 1.8 2009/09/19 16:14:09 nixnut Exp $

MODULE_AUTHOR=MSHELOR
inherit perl-module

DESCRIPTION="Perl extension for SHA-1/224/256/384/512"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

DEPEND="dev-lang/perl"

SRC_TEST="do"

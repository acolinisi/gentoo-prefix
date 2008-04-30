# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/xsdlib/xsdlib-20050627-r2.ebuild,v 1.2 2008/04/29 16:23:42 ranger Exp $

EAPI="prefix 1"
JAVA_PKG_IUSE="doc source"

inherit java-pkg-2 java-ant-2

MY_P="${PN}.${PV}"
DESCRIPTION="The Sun Multi-Schema XML Validator is a Java tool to validate XML documents against several kinds of XML schemata."
HOMEPAGE="https://msv.dev.java.net/"
SRC_URI="mirror://gentoo/${MY_P}.zip"

LICENSE="as-is Apache-1.1"
SLOT="0"
KEYWORDS="~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-macos"

RDEPEND=">=virtual/jre-1.4
	dev-java/xerces:2
	dev-java/relaxng-datatype:0"
DEPEND=">=virtual/jdk-1.4
	app-arch/unzip
	${RDEPEND}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	cp -i "${FILESDIR}/build-${PVR}.xml" build.xml || die

	rm -v *.jar || die
	mkdir lib && cd lib
	java-pkg_jarfrom relaxng-datatype
	java-pkg_jarfrom xerces-2
}

EANT_EXTRA_ARGS="-Dproject.name=${PN}"

src_install() {
	java-pkg_dojar dist/${PN}.jar

	dodoc README.txt || die
	dohtml HowToUse.html || die

	use doc && java-pkg_dojavadoc dist/doc/api
	use source && java-pkg_dosrc src/* src-apache/*
}

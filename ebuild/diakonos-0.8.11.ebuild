# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

DESCRIPTION="A Linux editor for the masses"
HOMEPAGE="http://purepistos.net/diakonos"
SRC_URI="http://purepistos.net/diakonos/diakonos-0.8.11.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
DEPEND=">=dev-lang/ruby-1.9"
RDEPEND="$DEPEND"

src_install() {
        cd ${S}
        ruby19 install.rb --dest-dir "${D}" || die "install failed"
}

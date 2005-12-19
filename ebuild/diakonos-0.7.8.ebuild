# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

IUSE=""

DESCRIPTION="A usable console text editor."
HOMEPAGE="http://purepistos.net/diakonos"
SRC_URI="http://purepistos.net/diakonos/${P}.tar.gz"
LICENSE="GPL-2"

SLOT="0"
KEYWORDS="~x86"
DEPEND="virtual/ruby"

src_install () {
	ruby setup.rb --prefix="${D}/usr" install || die "setup.rb install failed."
	dodoc README CHANGELOG
}

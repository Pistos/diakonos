#!/bin/sh

# This script is only for quickly making the tarballs.
# The make-release.rb script is the full script to run for making a release.

VERSION=`grep VERSION lib/diakonos/version.rb | head -n 1 | egrep -o '[0-9.]+'`
git archive --format=tar --prefix=diakonos-${VERSION}/ HEAD | bzip2 > diakonos-${VERSION}.tar.bz2
git archive --format=tar --prefix=diakonos-${VERSION}/ HEAD | gzip > diakonos-${VERSION}.tar.gz

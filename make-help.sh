#!/bin/bash

if [[ $# == 0 || $1 == --help ]]; then
    echo "$0 <version number>"
    exit 1
fi

VERSION=${1}

cp -r help "$VERSION" && \
tar czvf "diakonos-help-$VERSION.tar.gz" "$VERSION" && \
rm -rf "$VERSION"

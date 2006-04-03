#!/usr/bin/env ruby

require 'package'

Package.setup( "1.0" ) {
    name "Diakonos"
    version "0.8.1"
    author "Pistos"
    bin "diakonos"
    conf "etc/diakonos.conf"
}

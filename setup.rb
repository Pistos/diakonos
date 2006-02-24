#!/usr/bin/env ruby

require 'package'

Package.setup( "1.0" ) {
    name "Diakonos"
    version "0.8.0"
    author "Pistos"
    bin "diakonos"
    conf "diakonos.conf"
}

#!/usr/bin/env ruby

require 'benchmark'

keystrokes = Array( 1..9999999 ).map { rand( 254 - 32 ) + 32 }
PRINTABLE_CHARACTERS = [ *(32..126) ] + [ (128..254) ]
PRINTABLE_CHARACTERS2 = 32...254

def printable?( c )
    ( c >= 32 and c < 127 ) or
    ( c > 127 and c < 255 )
end
def printable2?( c )
    c >= 32 and c < 255 and c != 127
end

Benchmark.bm( 20 ) do |b|
    #b.report( "array include:" ) do
        #keystrokes.each do |c|
            #if PRINTABLE_CHARACTERS.include?( c )
            #end
        #end
    #end
    b.report( "range with exclude:" ) do
        keystrokes.each do |c|
            case c
                when PRINTABLE_CHARACTERS2
                    if c != 127
                    end
            end
        end
    end
    b.report( "comparison1:" ) do
        keystrokes.each do |c|
            if printable?( c )
            end
        end
    end
    b.report( "comparison2:" ) do
        keystrokes.each do |c|
            if printable2?( c )
            end
        end
    end
    b.report( "inline comparison1:" ) do
        keystrokes.each do |c|
            if(
                ( c >= 32 and c < 127 ) or
                ( c > 127 and c < 255 )
            )
            end
        end
    end
    b.report( "inline comparison2:" ) do
        keystrokes.each do |c|
            if(
                c >= 32 and c < 255 and c != 127
            )
            end
        end
    end
    b.report( "inline comparison3:" ) do
        keystrokes.each do |c|
            if(
                c > 31 and c < 255 and c != 127
            )
            end
        end
    end
end
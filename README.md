# Diakonos

## REQUIREMENTS

- Ruby 2.3+
- curses gem

Diakonos is built to run on Linux, but may run under other flavours of UNIX.
It works reasonably well under iTerm on OSX. It may or may not work on Windows.

Under Debian and Ubuntu derivatives, you'll need the following dependencies:

    sudo apt-get install libncurses5-dev ruby-dev ruby-curses


## INSTALLATION

    gem install diakonos


### RVM

If you use RVM[1], `gem install diakonos` will only install with the current
Ruby version and gemset. Diakonos may no longer be in the PATH after switching
Ruby versions or gemsets.

To make Diakonos available when it isn't installed in the current gemset, first
install it into an RVM Ruby version of your choice (and gemset, if you wish).
Then add a script like this in a directory in your PATH (such as
`~/bin/diakonos`):

    #!/bin/zsh

    source "$HOME/.rvm/scripts/rvm"
    rvm use 3.0.0@your-gemset
    diakonos

and make the script executable:

    chmod +x ~/bin/diakonos

[1]: https://rvm.io


## SOURCE CODE

The latest development code can be obtained from sourcehut:

    git clone https://git.sr.ht/~pistos/diakonos


## UNINSTALLATION

    gem uninstall diakonos


## USAGE

Run with any of these:

    diakonos [filename...]
    diakonos -s <session-name>
    diakonos -m <regexp>

or, for other options and arguments,

    diakonos --help

For help using Diakonos, simply press F1 or Shift-F1 from within the editor to
use the interactive help system.

To dig deeper into Diakonos' rich feature set, see https://github.com/Pistos/diakonos/wiki/Beyond-the-Basics .


----------------------------------------------------------------

Send comments, feedback and tech support requests to the ##pistos channel on
the Libera IRC network.

Reproducible issues may be reported at https://todo.sr.ht/~pistos/diakonos or
https://github.com/Pistos/diakonos/issues .



Pistos

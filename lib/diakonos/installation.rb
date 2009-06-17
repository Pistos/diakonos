# This file is completely overwritten by install.rb upon installation.
# This copy is here to permit the tests to execute.

module Diakonos
  INSTALL_SETTINGS = {
    :prefix   => '.',
    :bin_dir  => 'bin',
    :doc_dir  => '.',
    :help_dir => 'help',
    :conf_dir => '.',
    :lib_dir  => 'lib',
    :installed => {
      :files => [],
      :dirs => [],
    },
  }
end

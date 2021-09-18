# This file is completely overwritten by install.rb upon installation.
# This copy is here to permit the tests to execute.

module Diakonos
  root = File.expand_path("../..", __dir__)

  INSTALL_SETTINGS = {
    :prefix   => root,
    :bin_dir  => File.join(root, "bin"),
    :doc_dir  => root,
    :help_dir => File.join(root, "help"),
    :conf_dir => root,
    :lib_dir  => File.join(root, "lib"),
    :installed => {
      :files => [],
      :dirs => [],
    },
  }
end

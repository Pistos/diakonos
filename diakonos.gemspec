Gem::Specification.new do |s|
  s.add_runtime_dependency "curses", "1.4.4"
  s.authors     = ["Pistos"]
  s.bindir      = "bin"
  s.description = "Diakonos is a console text editor for the masses."
  s.email       = "diakonos dawt pistos aet purepistos dawt net"
  s.executables = "diakonos"

  s.files       = [
    "CHANGELOG",
    "diakonos.conf",
    "diakonos-256-colour.conf",
    "LICENCE.md",
    "bin/diakonos",
  ] +
  Dir["help/*"] +
  Dir["lib/**/*.rb"]

  s.homepage    = "https://git.sr.ht/~pistos/diakonos"
  s.license     = "GPL-3.0-only"
  s.metadata    = {
    "changelog_uri" => "https://git.sr.ht/~pistos/diakonos/tree/master/item/CHANGELOG",
    "homepage_uri" => "https://git.sr.ht/~pistos/diakonos",
    "source_code_uri" => "https://git.sr.ht/~pistos/diakonos",
  }
  s.name        = "diakonos"
  s.required_ruby_version = ">= 2.6", "< 4"
  s.summary     = "Console text editor for the masses"
  s.version     = "0.9.9"
end

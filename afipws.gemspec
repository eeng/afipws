# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "afipws/version"

Gem::Specification.new do |s|
  s.name        = "afipws"
  s.version     = Afipws::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Emmanuel Nicolau"]
  s.email       = ["emmanicolau@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Ruby wrapper para los servicios web de la AFIP}
  s.description = ""

  s.rubyforge_project = "afipws"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency "rspec"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "savon_spec"
  s.add_dependency "builder"
  s.add_dependency "savon"
  s.add_dependency "nokogiri"
  s.add_dependency "activesupport"
  s.add_dependency "i18n"
end

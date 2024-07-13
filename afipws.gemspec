$:.push File.expand_path("../lib", __FILE__)
require "afipws/version"

Gem::Specification.new do |s|
  s.name        = "afipws"
  s.version     = Afipws::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Emmanuel Nicolau"]
  s.email       = ["emmanicolau@gmail.com"]
  s.homepage    = "https://github.com/eeng/afipws"
  s.summary     = %q{Ruby client para los web services de la AFIP}
  s.description = ""

  s.rubyforge_project = "afipws"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_dependency "builder"
  s.add_dependency "savon", '~> 2.15.0'
  s.add_dependency "httpclient"
  s.add_dependency "nokogiri"
  s.add_dependency "activesupport"
end

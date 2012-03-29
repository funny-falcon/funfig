# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "funfig/version"

Gem::Specification.new do |s|
  s.name        = "funfig"
  s.version     = Funfig::VERSION
  s.authors     = ["Sokolov Yura 'funny-falcon'"]
  s.email       = ["funny.falcon@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Configuration with calculable defaults}
  s.description = %q{Defines configuration schema with calculable defaults}

  s.rubyforge_project = "funfig"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nifti/version"

Gem::Specification.new do |s|
  s.name        = "nifti"
  s.version     = NIFTI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Erik Kastman"]
  s.email       = ["ekk@medicine.wisc.edu"]
  s.homepage    = ""
  s.summary     = %q{A pure Ruby API to the NIfTI Neuroimaging Format}
  s.description = %q{A pure Ruby API to the NIfTI Neuroimaging Format}

  s.rubyforge_project = "nifti"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "narray"
end

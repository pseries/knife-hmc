# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-hmc/version'

Gem::Specification.new do |spec|
  spec.name          = "knife-hmc"
  spec.version       = Knife::Hmc::VERSION
  spec.authors       = ["John J. Rofrano"]
  spec.email         = ["rofrano@us.ibm.com"]
  spec.summary       = %q{IBM Hardware Management Console support for Chef's Knife Command}
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/rofrano/knife-hmc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  #spec.add_development_dependency "remote_hmc"

end

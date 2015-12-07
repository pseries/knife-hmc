# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-hmc/version'

Gem::Specification.new do |spec|
  spec.name          = "knife-hmc"
  spec.version       = Knife::Hmc::VERSION
  spec.authors       = ["John J. Rofrano,Christopher M. Wood, John F. Hutchinson"]
  spec.email         = ["rofrano@us.ibm.com, woodc@us.ibm.com, jfhutchi@us.ibm.com"]
  spec.summary       = %q{IBM Hardware Management Console support for Chef's Knife Command}
  spec.description   = spec.summary
  spec.homepage      = "http://github.com/pseries/knife-hmc"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("rbvppc", "~> 1.0.0")

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 0"
  spec.required_ruby_version = '>= 2.1.0'
end

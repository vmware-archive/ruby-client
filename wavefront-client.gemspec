=begin
    Copyright 2015 Wavefront Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
   limitations under the License.

=end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wavefront/client/version'

Gem::Specification.new do |spec|
  spec.name          = "wavefront-client"
  spec.version       = Wavefront::Client::VERSION
  spec.authors       = ["Sam Pointer", "Louis McCormack", "Joshua McGhee", "Conor Beverland", "Salil Deshmukh", "Rob Fisher"]
  spec.email         = ["support@wavefront.com"]
  spec.description   = %q{A simple abstraction for talking to Wavefront in Ruby. Includes a command-line interface.}
  spec.summary       = %q{A simple abstraction for talking to Wavefront in Ruby}
  spec.homepage      = "https://github.com/wavefrontHQ/ruby-client"
  spec.license       = "Apache License 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.5.0"
  spec.add_development_dependency 'yard',  '~> 0.9.5'

  spec.add_dependency "rest-client", ">= 1.6.7", "< 1.8"
  spec.add_dependency "docopt", "~> 0.5.0"
  spec.add_dependency 'inifile',  '3.0.0'
  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
end

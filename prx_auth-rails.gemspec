# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prx_auth/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "prx_auth-rails"
  spec.version       = PrxAuth::Rails::VERSION
  spec.authors       = ["Chris Rhoden"]
  spec.email         = ["carhoden@gmail.com"]
  spec.description   = "Rails integration for next generation PRX Authorization system."
  spec.summary       = "Rails integration for next generation PRX Authorization system."
  spec.homepage      = "https://github.com/PRX/prx_auth-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'actionpack'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'coveralls', '~> 0'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency "rails", "~> 6.1.0"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sqlite3'

  spec.add_runtime_dependency 'prx_auth', ">= 1.7.0"
end

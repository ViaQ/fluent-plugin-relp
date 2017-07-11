# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name        = 'fluent-plugin-relp'
  gem.version     = '0.1.3'
  gem.author      = "Jiří Vymazal"
  gem.email       = ['jvymazal@redhat.com']
  gem.summary     = "Fluent plugin to receive messages via RELP"
  gem.description = "Plugin allowing recieving log messages via RELP protocol from e.g. syslog"
  gem.homepage    = 'https://github.com/ViaQ/fluent-plugin-relp'
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency 'rake', '~> 0'
  gem.add_development_dependency 'test-unit', '~> 3.1'
  gem.add_runtime_dependency 'fluentd', '~> 0.12.0'
  gem.add_runtime_dependency 'relp', '~> 0.1'
end

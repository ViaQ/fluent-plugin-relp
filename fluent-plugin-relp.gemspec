# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-relp"
  gem.version     = "0.1"
  gem.authors     = ["Jiří Vymazal"]
  gem.email       = ["jvymazal@redhat.com"]
  gem.summary     = %q{Fluent plugin to receive messages via RELP}
  gem.description = %q{Plugin allowing recieving log messages via RELP protocol from e.g. syslog}
  gem.homepage    = "https://github.com/ViaQ/fluent-plugin-relp"
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency 'rake', '~> 0'
  gem.add_runtime_dependency 'fluentd', '~> 0'
  gem.add_runtime_dependency 'relp', '~> 0.0'
end

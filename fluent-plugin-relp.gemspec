lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent/plugin/relp/version'

Gem::Specification.new do |gem|
  gem.name        = 'fluent-plugin-relp'
  gem.version     = Fluent::RelpPlugin::VERSION
  gem.author      = 'Jiří Vymazal'
  gem.email       = ['jvymazal@redhat.com']
  gem.summary     = 'Fluent plugin to receive messages via RELP'
  gem.description = 'Plugin allowing recieving log messages via RELP protocol from e.g. syslog'
  gem.homepage    = 'https://github.com/ViaQ/fluent-plugin-relp'
  gem.license     = 'MIT'

  gem.files         = Dir['{lib,bin,test}/**/*'] + ['LICENSE.txt', 'README.md', 'Rakefile', 'CHANGELOG.md']
  gem.test_files    = Dir['{test}/**/*']
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency 'coveralls', '~> 0'
  gem.add_development_dependency 'rake', '~> 0'
  gem.add_development_dependency 'simplecov', '~> 0'
  gem.add_development_dependency 'test-unit', '~> 3.1'
  gem.add_runtime_dependency 'fluentd', '~> 1'
  gem.add_runtime_dependency 'relp', '~> 0.2'
end

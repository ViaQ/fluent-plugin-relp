# IMPORTANT: for code coverage testing to work, these lines MUST
# stay right on top (before anything else)
require 'simplecov'
require 'coveralls'

# Use both simplecov local and coveralls remote coverage reports.
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])
SimpleCov.start

# rest can continue below
###############################################################################
require 'bundler/setup'
require 'test/unit'
require 'fluent/test'

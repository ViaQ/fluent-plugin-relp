# IMPORTANT: for code coverage testing to work, the 4 below lines MUST
# stay right on top (before anything else)
require 'simplecov'
SimpleCov.start
require 'coveralls'
Coveralls.wear!
# rest can continue below
###############################################################################
require 'bundler/setup'
require 'test/unit'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'

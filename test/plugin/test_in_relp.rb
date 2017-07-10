require 'helper'
require 'fluent/plugin/in_relp'

class RelpInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    bind       		HOST
    port		1111
    tag                 input.relp
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::RelpInput).configure(conf)
  end

  sub_test_case "config" do
    def test_empty
      assert_raise(Fluent::ConfigError) {
        create_driver('')
      }
    end

    def test_configure
      d = create_driver
      assert_equal 'HOST', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
    end
  end
end

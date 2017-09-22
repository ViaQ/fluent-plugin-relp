require 'helper'
require 'fluent/plugin/in_relp'

class RelpServerFake
  def initialize(callback)
    @callback = callback
  end

  def run
    @run_invoked = true
  end
  attr_reader :run_invoked

  def send(msg)
    @callback.call(msg)
  end

  def server_shutdown
    @shut_down = true
  end
  attr_reader :shut_down
end

class JoinException < RuntimeError
end

class RelpInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    bind       		HOST
    port		1111
    tag                 input.relp
    ssl_config          ./cert.pem:./key.pem:./ca.pem
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

  sub_test_case "function" do
    def test_run_invalid
      d = create_driver
      assert_raise(SocketError) { #will fail because of invalid bind
	d.run
      }
    end

    def test_run
      d = create_driver
      server = RelpServerFake.new(d.instance.method(:on_message))
      d.instance.instance_variable_set(:@server, server)
      d.instance.run
      assert_equal true, server.run_invoked
    end

    def test_message
      d = create_driver
      server = RelpServerFake.new(d.instance.method(:on_message))
      assert_raise(SocketError) { #will fail because of invalid bind
	d.run
      }
      d.instance.instance_variable_set(:@server, server)
      d.instance.run
      message = 'testLog'
      server.send(message)
      assert_equal true, d.emit_streams.count > 0
      assert_equal d.emit_streams[0][0], 'input.relp' #[0][0] indicates tag of first accepted message
      assert_equal d.emit_streams[0][1][0][1]["message"], message #this is how you access first accepted record... blame fluentd test framework
    end
  end

  sub_test_case "cleanup" do
    def test_shutdown
      d = create_driver
      server = RelpServerFake.new(d.instance.method(:on_message))
      d.instance.instance_variable_set(:@server, server)
      plugin_thread = Thread.new { raise JoinException }
      d.instance.instance_variable_set(:@thread, plugin_thread)
      assert_raise(JoinException) {
	d.instance.shutdown
      }
      assert_equal true, server.shut_down
    end
  end
end

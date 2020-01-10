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

  def send(msg, peer)
    @callback.call(msg, peer)
  end

  def server_shutdown
    @shut_down = true
  end
  attr_reader :shut_down
end

class JoinTestThread < Thread
  @joined = false
  attr_accessor :joined
  def join
    super
    @joined = true
  end
end

class RelpInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %(
    bind                localhost
    port                1111
    tag                 input.relp
    <ssl_cert>
      cert              test/server.pem
      key               test/server.key
    </ssl_cert>
    ssl_ca_file         ca.pem
  )

  def create_driver(conf = CONFIG)
    d = Fluent::Test::InputTestDriver.new(Fluent::RelpInput)
    d.configure(conf)
    return d
  end

  sub_test_case 'config' do
    def test_empty
      assert_raise(Fluent::ConfigError) do
        create_driver('')
      end
    end

    def test_configure
      d = create_driver
      assert_equal 'localhost', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
      assert_equal 'test/server.pem', d.instance.ssl_certs[0].cert
      assert_equal 'test/server.key', d.instance.ssl_certs[0].key
    end

    def test_configure_complex
      conf = %(
        bind                localhost
        port                1111
        tag                 input.relp
        peer_field          foo
        <ssl_cert>
          cert              test/server.pem
          key               test/server.key
          <extra_cert>
            cert            test/ca.pem
          </extra_cert>
          <extra_cert>
            cert            test/ca.pem
          </extra_cert>
        </ssl_cert>
        <ssl_cert>
          cert              test/server.pem
          key               test/server.key
        </ssl_cert>
        ssl_ca_file         test/ca.pem
      )
      d = create_driver(conf)
      assert_equal 'localhost', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
      assert_equal 'foo', d.instance.peer_field
      assert_equal 'test/server.pem', d.instance.ssl_certs[0].cert
      assert_equal 'test/server.key', d.instance.ssl_certs[0].key
      assert_equal 'test/ca.pem', d.instance.ssl_certs[0].extra_certs[0].cert
      assert_equal 'test/ca.pem', d.instance.ssl_certs[0].extra_certs[1].cert
      assert_equal 'test/server.pem', d.instance.ssl_certs[1].cert
      assert_equal 'test/server.key', d.instance.ssl_certs[1].key
    end
  end

  sub_test_case 'function' do
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
      d.run
      d.instance.instance_variable_set(:@server, server)
      d.instance.run
      message = 'testLog'
      peer = 'testPeer'
      server.send(message, peer)
      assert_equal true, d.emit_streams.count.positive?
      assert_equal d.emit_streams[0][0], 'input.relp' # [0][0] indicates tag of first accepted message
      assert_equal d.emit_streams[0][1][0][1]['message'], message # this is how you access first accepted record... blame fluentd test framework
      assert_equal d.emit_streams[0][1][0][1]['peer'], peer # this is how you access first accepted record... blame fluentd test framework
    end
  end

  sub_test_case 'cleanup' do
    def test_shutdown
      d = create_driver
      server = RelpServerFake.new(d.instance.method(:on_message))
      d.instance.instance_variable_set(:@server, server)
      plugin_thread = JoinTestThread.new {}
      d.instance.instance_variable_set(:@thread, plugin_thread)
      d.instance.shutdown
      assert_equal true, plugin_thread.joined
      assert_equal true, server.shut_down
    end
  end
end

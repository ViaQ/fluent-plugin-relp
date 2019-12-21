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

  CONFIG = %(
    bind                HOST
    port		            1111
    tag                 input.relp
    <ssl_cert>
      cert              cert.pem
      key               key.pem
    </ssl_cert>
    ssl_ca_file         ca.pem
  )

  def create_driver(conf = CONFIG)
    File.open('cert.pem', 'w')
    File.open('key.pem', 'w')
    File.open('ca.pem', 'w')
    Fluent::Test::InputTestDriver.new(Fluent::RelpInput).configure(conf)
  end

  sub_test_case 'config' do
    def test_empty
      assert_raise(Fluent::ConfigError) do
        create_driver('')
      end
    end

    def test_configure
      d = create_driver
      assert_equal 'HOST', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
      assert_equal 'cert.pem', d.instance.ssl_certs[0].cert
      assert_equal 'key.pem', d.instance.ssl_certs[0].key
    end

    def test_configure_complex
      conf = %(
        bind                HOST
        port		            1111
        tag                 input.relp
        <ssl_cert>
          cert              cert.pem
          key               key.pem
          <extra_cert>
            cert            extra1.pem
          </extra_cert>
          <extra_cert>
            cert            extra2.pem
          </extra_cert>
        </ssl_cert>
        <ssl_cert>
          cert              cert2.pem
          key               key2.pem
        </ssl_cert>
        ssl_ca_file         ca.pem
      )
      d = create_driver(conf)
      assert_equal 'HOST', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
      assert_equal 'cert.pem', d.instance.ssl_certs[0].cert
      assert_equal 'key.pem', d.instance.ssl_certs[0].key
      assert_equal 'extra1.pem', d.instance.ssl_certs[0].extra_certs[0].cert
      assert_equal 'extra2.pem', d.instance.ssl_certs[0].extra_certs[1].cert
      assert_equal 'cert2.pem', d.instance.ssl_certs[1].cert
      assert_equal 'key2.pem', d.instance.ssl_certs[1].key
    end

    def test_configure_legacy
      conf = %(
        bind       		HOST
        port		1111
        tag                 input.relp
        ssl_config          ./cert.pem:./key.pem:./ca.pem
      )
      d = create_driver(conf)
      assert_equal 'HOST', d.instance.bind
      assert_equal 1111, d.instance.port
      assert_equal 'input.relp', d.instance.tag
      assert_equal './cert.pem:./key.pem:./ca.pem', d.instance.ssl_config
    end
  end

  sub_test_case 'function' do
    def test_run_invalid
      d = create_driver
      assert_raise(OpenSSL::X509::CertificateError) do # will fail because of no valid cert
        d.run
      end
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
      assert_raise(OpenSSL::X509::CertificateError) do # will fail because of no valid cert
        d.run
      end
      d.instance.instance_variable_set(:@server, server)
      d.instance.run
      message = 'testLog'
      server.send(message)
      assert_equal true, d.emit_streams.count.positive?
      assert_equal d.emit_streams[0][0], 'input.relp' # [0][0] indicates tag of first accepted message
      assert_equal d.emit_streams[0][1][0][1]['message'], message # this is how you access first accepted record... blame fluentd test framework
    end
  end

  sub_test_case 'cleanup' do
    def test_shutdown
      d = create_driver
      server = RelpServerFake.new(d.instance.method(:on_message))
      d.instance.instance_variable_set(:@server, server)
      plugin_thread = Thread.new { raise JoinException }
      d.instance.instance_variable_set(:@thread, plugin_thread)
      assert_raise(JoinException) do
        d.instance.shutdown
      end
      assert_equal true, server.shut_down
    end
  end
end

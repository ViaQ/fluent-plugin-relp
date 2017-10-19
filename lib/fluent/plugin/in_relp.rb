require 'fluent/input'
require 'relp'

module Fluent
  class RelpInput < Input
    Fluent::Plugin.register_input('relp', self)

    desc 'Tag of output events.'
    config_param :tag, :string
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'
    desc 'SSL configuration string, format "certificate_path":"key_path":"certificate_authority_path"'
    config_param :ssl_config, :string, default: nil

    def configure(conf)
        super
    end

    def start
	super
	ssl_context = nil
	if @ssl_config != nil
		ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2)
		ssl_context.ca_file = @ssl_config.split(':')[2]
		ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
		ssl_context.key = OpenSSL::PKey::RSA.new(File.open(@ssl_config.split(':')[1]))
		ssl_context.cert = OpenSSL::X509::Certificate.new(File.open(@ssl_config.split(':')[0]))
	end
	@server = Relp::RelpServer.new(@port, method(:on_message), @bind, ssl_context, log)
        @thread = Thread.new(&method(:run))
    end

    def shutdown
	super
	@server.server_shutdown
        @thread.join
    end

    def run
        @server.run()
      rescue => e
        log.error "unexpected error", error: e, error_class: e.class
        log.error_backtrace
    end

    def on_message(msg)
	  time = Engine.now
	  record = {"message"=> msg}
	  router.emit(@tag, time, record)
      rescue => e
        log.error msg.dump, error: e, error_class: e.class
        log.error_backtrace
    end
  end
end


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

    def configure(conf)
        super
    end

    def start
	@server = Relp::RelpServer.new(@bind, @port, log, method(:on_message))
        @thread = Thread.new(&method(:run))
    end

    def shutdown
	super
	@server.server_shut_down
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
	  router.emit(@tag, time, msg.dump)
      rescue => e
        log.error msg.dump, error: e, error_class: e.class
        log.error_backtrace
    end
  end
end


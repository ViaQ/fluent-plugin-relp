require 'fluent/input'
require 'ipaddr'
require 'cool.io'

module Fluent
  class TcpHandler < Coolio::Socket
      PEERADDR_FAILED = ["?", "?", "name resolusion failed", "?"]

      def initialize(io, log, delimiter, callback, resolve_hostname = false)
        super(io)
        if io.is_a?(TCPSocket)
          io.do_not_reverse_lookup = resolve_hostname
          @addr = (io.peeraddr rescue PEERADDR_FAILED)

          opt = [1, @timeout.to_i].pack('I!I!')  # { int l_onoff; int l_linger; }
          io.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, opt)
        end
        @delimiter = delimiter
        @callback = callback
        @log = log
        @log.trace { "accepted fluent socket object_id=#{self.object_id}" }
        @buffer = "".force_encoding('ASCII-8BIT')
      end

      def on_connect
      end

      def on_read(data)
        @buffer << data
        pos = 0

        while i = @buffer.index(@delimiter, pos)
          msg = @buffer[pos...i]
          @callback.call(msg, @addr)
          pos = i + @delimiter.length
        end
        @buffer.slice!(0, pos) if pos > 0
      rescue => e
        @log.error "unexpected error", error: e, error_class: e.class
        close
      end

      def on_close
        @log.trace { "closed fluent socket object_id=#{self.object_id}" }
      end
  end

  class RelpInput < Input
    # First, register the plugin. NAME is the name of this plugin
    # and identifies the plugin in the configuration file.
    Fluent::Plugin.register_input('relp', self)

    desc 'Tag of output events.'
    config_param :tag, :string
    # config_param defines a parameter. You can refer a parameter via @port instance variable
    # :default means this parameter is optional
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'

    desc "The max bytes of message"
    config_param :message_length_limit, :size, default: 4096

    config_param :blocking_timeout, :time, default: 0.5

    # syslog family add "\n" to each message and this seems only way to split messages in tcp stream
    desc 'The payload is read up to this character.'
    config_param :delimiter, :string, default: "\n"

    # This method is called before starting.
    # 'conf' is a Hash that includes configuration parameters.
    # If the configuration is invalid, raise Fluent::ConfigError.
    def configure(conf)
        super
    end

    # This method is called when starting.
    # Open sockets or files and create a thread here.
    def start
        @loop = Coolio::Loop.new
        @handler = listen(method(:on_message))
        @loop.attach(@handler)
        @thread = Thread.new(&method(:run))
    end

    # This method is called when shutting down.
    # Shutdown the thread and close sockets or files here.
    def shutdown
        @loop.watchers.each { |w| w.detach }
        @loop.stop
        @handler.close
        @thread.join
    end

    def run
        @loop.run(@blocking_timeout)
      rescue => e
        log.error "unexpected error", error: e, error_class: e.class
        log.error_backtrace
    end

    def listen(callback)
      log.info "listening tcp socket on #{@bind}:#{@port}"
      Coolio::TCPServer.new(@bind, @port, TcpHandler, log, @delimiter, callback, !!@source_hostname_key)
    end

    private

    def on_message(msg, addr)
	  time = Engine.now
	  router.emit(@tag, time, msg.dump)
      rescue => e
        log.error msg.dump, error: e, error_class: e.class, host: addr[3]
        log.error_backtrace
    end
  end
end

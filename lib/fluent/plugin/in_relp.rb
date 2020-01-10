require 'fluent/input'
require 'fluent/plugin/relp/version'
require 'relp'
require 'relp/version'

module Fluent
  class RelpInput < Input
    Fluent::Plugin.register_input('relp', self)

    desc 'Tag of output events.'
    config_param :tag, :string
    desc 'Specify the record field to store peer information'
    config_param :peer_field, :string, default: 'peer'.freeze
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'

    config_section :ssl_cert, param_name: :ssl_certs, multi: true, required: false do
      desc 'Path to server SSL cert'
      config_param :cert, :string
      desc 'Path to server SSL cert key'
      config_param :key, :string
      config_section :extra_cert, param_name: :extra_certs, multi: true, required: false do
        desc 'Path to extra server SSL certs'
        config_param :cert, :string
      end
    end
    desc 'SSL ca_file for clients'
    config_param :ssl_ca_file, :string, default: nil

    @ssl_context = nil

    def configure(conf)
      super
      if !@ssl_certs.empty? || !@ssl_ca_file.nil?
        @ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2)
      end
      @ssl_certs.each do |ssl_cert|
        cert = OpenSSL::X509::Certificate.new(File.open(ssl_cert.cert))
        key = OpenSSL::PKey::RSA.new(File.open(ssl_cert.key))
        extra = []
        ssl_cert.extra_certs.each do |extra_cert|
          extra << OpenSSL::X509::Certificate.new(File.open(extra_cert.cert))
        end
        @ssl_context.add_certificate(cert, key, extra)
      end
      if @ssl_ca_file
        @ssl_context.ca_file = @ssl_ca_file
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end

    def start
      super
      log.info "config complete, RELP plugin:'v", RelpPlugin::VERSION, "' with RELP lib:'v", Relp::VERSION, "' starting..."
      @server = Relp::RelpServer.new(@port, method(:on_message), @bind, @ssl_context, log)
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      super
      @server.server_shutdown
      @thread.join
    end

    def run
      @server.run
    rescue StandardError => e
      log.error 'unexpected error', error: e, error_class: e.class
      log.error_backtrace
    end

    def on_message(msg, peer)
      time = Engine.now
      record = { 'message' => msg.chomp, @peer_field => peer }
      router.emit(@tag, time, record)
    rescue StandardError => e
      log.error msg.dump, error: e, error_class: e.class
      log.error_backtrace
    end
  end
end

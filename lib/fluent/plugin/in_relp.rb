require 'fluent/input'
require 'fluent/plugin/relp/version'
require 'relp'
require 'relp/version'

module Fluent
  class RelpInput < Input
    Fluent::Plugin.register_input('relp', self)

    desc 'Tag of output events.'
    config_param :tag, :string
    desc 'The port to listen to.'
    config_param :port, :integer, default: 5170
    desc 'The bind address to listen to.'
    config_param :bind, :string, default: '0.0.0.0'
    desc 'SSL configuration string, format certificate_path:key_path:certificate_authority_path'
    config_param :ssl_config, :string, default: nil, deprecated: 'Use ssl_cert and ssl_ca_file instead'

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

    def configure(conf)
      super
    end

    def start
      super
      ssl_context = nil
      if !@ssl_config.nil? || !@ssl_certs.empty? || !@ssl_ca_file.nil?
        ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_2)
      end
      unless @ssl_config.nil?
        ssl_context.ca_file = @ssl_config.split(':')[2]
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        key = OpenSSL::PKey::RSA.new(File.open(@ssl_config.split(':')[1]))
        cert = OpenSSL::X509::Certificate.new(File.open(@ssl_config.split(':')[0]))
        ssl_context.add_certificate(cert, key)
      end
      @ssl_certs.each do |ssl_cert|
        cert = OpenSSL::X509::Certificate.new(File.open(ssl_cert.cert))
        key = OpenSSL::PKey::RSA.new(File.open(ssl_cert.key))
        extra = []
        ssl_cert.extra_certs.each do |extra_cert|
          extra << OpenSSL::X509::Certificate.new(File.open(extra_cert.cert))
        end
        ssl_context.add_certificate(cert, key, extra)
      end
      if @ssl_ca_file
        ssl_context.ca_file = @ssl_ca_file
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      log.info "config complete, RELP plugin:'v", RelpPlugin::VERSION, "' with RELP lib:'v", Relp::VERSION, "' starting..."
      @server = Relp::RelpServer.new(@port, method(:on_message), @bind, ssl_context, log)
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
      retry
    end

    def on_message(msg)
      time = Engine.now
      record = { 'message' => msg }
      router.emit(@tag, time, record)
    rescue StandardError => e
      log.error msg.dump, error: e, error_class: e.class
      log.error_backtrace
    end
  end
end

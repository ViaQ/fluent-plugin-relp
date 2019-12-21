# RELP input plugin

Plugin for input to fluentd using [RELP protocol](http://www.rsyslog.com/doc/relp.html)

this depends on `relp` ruby gem which host server-side ruby implementation, available [here](https://github.com/ViaQ/Relp).

[![Gem Version](https://badge.fury.io/rb/fluent-plugin-relp.png)](http://badge.fury.io/rb/fluent-plugin-relp)
[![Build Status](https://travis-ci.org/ViaQ/fluent-plugin-relp.png?branch=master)](https://travis-ci.org/ViaQ/fluent-plugin-relp)
[![Coverage Status](https://coveralls.io/repos/github/ViaQ/fluent-plugin-relp/badge.svg?branch=master)](https://coveralls.io/github/ViaQ/fluent-plugin-relp?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-relp'
```

Or install it yourself as:

    $ gem install fluent-plugin-relp

just note that you will probably need ruby development libraries installed to do this.

You can also install through `bundler` and use `rake test` to run unit tests for plugin.

## Usage

To use the plugin just add tou your fluent.conf file:
```aconf
<source>
  @type relp
  #optionally, specify port on which to start relp server, defaults to 5170
  port XXXX
  #optionally, specify a tag with which to mark messages received over this connection
  tag your_tag_for_relp
  #optionally, determine remote IP to bind to, by default binds to all incoming connections
  bind XX.XX.XX.XX
  #if you want to use TLS encryption specify this
  <ssl_cert>
    cert /path_to/certificate_file
    key /path_to/key_file
    <extra_cert>
      cert /path_to/chain_file
    </extra_cert>
  </ssl_cert>
  #if you need a CA file to verify clients specify this
  ssl_ca_file /path_to/certificate_authority_file
</source>

```
With the above set up your fluentd is ready to accept messages transported by RELP, for example logs
sent by rsyslog's `omrelp` module, example of setting up (/etc/rsyslog.conf file):

```aconf
module(load="omrelp")

*.* action(type="omrelp"
	Target="your_fluentd_host_or_ip"
	Port="5170_or_yours_set"
	# Add below part to use SSL encryption
	tls="on"
	tls.permittedPeer="your_fluentd_host"
	tls.authMode="name"
	tls.mycert="/path_to/syslog_host_certificate_file"
	tls.myprivkey="/path_to/syslog_host_key_file"
	tls.cacert="/path_to/certificate_authority_file_for_fluentd_host"
	)
```
make sure you have librelp and rsyslog relp plugin present on your system.

Also you need to make sure that things lige firewall and selinux are set up
so they do not block communication on configured port(s) and adress(es).

Additionally, if you have problems estabilishing connection over network, it may
help to increase timeouts for socket connection and/or RELP session on clients.

That is all you need to reliably send system logs to remote fluentd instance.

## Contributing

Before filing a bug check whether you are using latest version AND latest version of [Relp library](https://github.com/ViaQ/Relp).
Bug reports and pull requests are welcome on GitHub at https://github.com/ViaQ/fluent-plugin-relp.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

#! /usr/bin/env ruby
#
#   mesos-metrics
#
# DESCRIPTION:
#   This plugin extracts the stats from a mesos master or slave
#
# OUTPUT:
#    metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#   gem: socket
#   gem: json
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Tom Stockton (tom@stocktons.org.uk)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'socket'
require 'json'

# Mesos default ports are defined here: http://mesos.apache.org/documentation/latest/configuration
MASTER_DEFAULT_PORT ||= '5050'.freeze
SLAVE_DEFAULT_PORT ||= '5051'.freeze

class MesosMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :mode,
         description: 'master or slave',
         short: '-m MODE',
         long: '--mode MODE',
         required: true

  option :scheme,
         description: 'Metric naming scheme',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: Socket.gethostname.to_s

  option :server,
         description: 'Mesos Host',
         short: '-h SERVER',
         long: '--host SERVER',
         default: 'localhost'

  option :port,
         description: "port (default #{MASTER_DEFAULT_PORT} for master, #{SLAVE_DEFAULT_PORT} for slave)",
         short: '-p PORT',
         long: '--port PORT',
         required: false

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/metrics/snapshot'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    uri = config[:uri]
    case config[:mode]
    when 'master'
      port = config[:port] || MASTER_DEFAULT_PORT
    when 'slave'
      port = config[:port] || SLAVE_DEFAULT_PORT
    end
    scheme = "#{config[:scheme]}.mesos-#{config[:mode]}"
    begin
      r = RestClient::Resource.new("http://#{config[:server]}:#{port}#{uri}", timeout: config[:timeout]).get
      JSON.parse(r).each do |k, v|
        k_copy = k.tr('/', '.')
        output([scheme, k_copy].join('.'), v)
      end
    rescue Errno::ECONNREFUSED
      critical "Mesos #{config[:mode]} is not responding"
    rescue RestClient::RequestTimeout
      critical "Mesos #{config[:mode]} Connection timed out"
    end
    ok
  end
end

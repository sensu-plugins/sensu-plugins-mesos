#! /usr/bin/env ruby
#
#   check-chronos
#
# DESCRIPTION:
#   This plugin checks that Chronos can query the existing job graph.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Tom Stockton (tom@stocktons.org.uk)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'

class ChronosNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Chronos hosts, comma separated',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Chronos port',
         short: '-p PORT',
         long: '--port PORT',
         default: '80'

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/scheduler/jobs'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    servers = config[:server]
    uri = config[:uri]
    failures = []
    servers.split(',').each do |server|
      begin
        r = RestClient::Resource.new("http://#{server}:#{config[:port]}#{uri}", timeout: config[:timeout]).get
        if r.code != 200
          failures << "Chronos on #{server} is not responding"
        end
      rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
        failures << "Chronos on #{server} is not responding"
      rescue RestClient::RequestTimeout
        failures << "Chronos on #{server} connection timed out"
      end
    end
    if failures.empty?
      ok "Chronos is running on #{servers}"
    else
      critical failures.join("\n")
    end
  end
end

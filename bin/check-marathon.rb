#! /usr/bin/env ruby
#
#   check-marathon
#
# DESCRIPTION:
#   This plugin checks that the ping url returns 200 OK
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
#   #YELLOW
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

class MarathonNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Marathon servers, comma separated',
         short: '-s SERVER1,SERVER2,...',
         long: '--server SERVER1,SERVER2,...',
         default: 'localhost'

  option :port,
         description: 'Marathon port',
         short: '-p PORT',
         long: '--port PORT',
         required: false,
         default: '8080'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    servers = config[:server]
    failures = []
    servers.split(',').each do |server|
      begin
        r = RestClient::Resource.new("http://#{server}:#{config[:port]}/ping", timeout: config[:timeout]).get
        if r.code != 200
          failures << "Marathon Service on #{server} is not responding"
        end
      rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
        failures << "Marathon Service on #{server} is not responding"
      rescue RestClient::RequestTimeout
        failures << "Marathon Service on #{server} connection timed out"
      end
    end
    if failures.empty?
      ok "Marathon Service is up on #{servers}"
    else
      critical failures.join("\n")
    end
  end
end

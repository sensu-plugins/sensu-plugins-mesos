#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-metronome
#
# DESCRIPTION:
#   This plugin checks that Metronome can query the existing job graph.
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
#   Copyright 2017, PTC (www.ptc.com)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'

class MetronomeNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Metronome hosts, comma separated',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Metronome port',
         short: '-p PORT',
         long: '--port PORT',
         default: '9942'

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/v1/jobs'

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
          failures << "Metronome on #{server} is not responding"
        end
      rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
        failures << "Metronome on #{server} is not responding"
      rescue RestClient::RequestTimeout
        failures << "Metronome on #{server} connection timed out"
      end
    end
    if failures.empty?
      ok "Metronome is running on #{servers}"
    else
      critical failures.join("\n")
    end
  end
end

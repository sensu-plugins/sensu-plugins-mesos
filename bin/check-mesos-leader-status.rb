#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-mesos-leader-status
#
# DESCRIPTION:
#   This plugin checks that the health url of the leader master returns 200 OK
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
#   Copyright 2016, Oskar Flores (oskar.flores@gmail.com)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'

class MesosLeaderNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Mesos server',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'port (default 5050)',
         short: '-p PORT',
         long: '--port PORT',
         default: 5050,
         required: false

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/redirect'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    server = config[:server]
    port = config[:port]
    uri = config[:uri]
    begin
      r = RestClient::Resource.new("http://#{server}:#{port}#{uri}", timeout: config[:timeout]).get
      if r.code == 503
        critical "Master on #{server} is not responding"
      end
    rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
      critical "Mesos on #{server} is not responding"
    rescue RestClient::RequestTimeout
      critical "Mesos on #{server} connection timed out"
    end
    ok
  end
end

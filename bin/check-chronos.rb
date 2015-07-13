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

class ChronosNodeStatus < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Chronos host',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Chronos port',
         short: '-p PORT',
         long: '--port PORT',
         default: '80'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  def run
    r = RestClient::Resource.new("http://#{config[:server]}:#{config[:port]}/scheduler/jobs", timeout: config[:timeout]).get
    if r.code == 200
      ok 'Chronos Service is up'
    else
      critical 'Chronos Service is not responding'
    end
  rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound
    critical 'Chronos Service is not responding'
  rescue RestClient::RequestTimeout
    critical 'Chronos Service Connection timed out'
  end
end

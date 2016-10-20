#! /usr/bin/env ruby
#
#   check-mesos-running-tasks
#
# DESCRIPTION:
#   This plugin checks that there are running tasks on a mesos cluster
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
#   gem: json
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
require 'json'
require 'daybreak'

class MesosRunningTaskCheck < Sensu::Plugin::Check::CLI
  check_name 'CheckMesosRunningTask'
  @metrics_name = 'master/tasks_running'.freeze

  class << self
    attr_reader :metrics_name
  end

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
         default: '/metrics/snapshot'

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  option :mode,
         description: 'eq ne lt gt or rg',
         short: '-m MODE',
         long: '--mode MODE',
         required: true

  option :min,
         description: 'min value on range',
         short: '-l VALUE',
         long: '--low VALUE',
         required: false,
         proc: proc(&:to_i),
         derfault: 0

  option :max,
         description: 'max value on range',
         short: '-h VALUE',
         long: '--high VALUE',
         required: false,
         proc: proc(&:to_i),
         default: 1

  option :value,
         description: 'value to check against',
         short: '-v VALUE',
         long: '--value VALUE',
         proc: proc(&:to_i),
         default: 0,
         required: false

  option :delta,
         short: '-d',
         long: '--delta',
         description: 'Use this flag to compare the metric with the previously retrieved value',
         boolean: true

  def run
    port = config[:port]
    uri = config[:uri]
    timeout = config[:timeout]
    mode = config[:mode]
    value = config[:value]
    server = config[:server]
    min = config[:min]
    max = config[:max]

    begin
      server = get_leader_url server, port
      r = RestClient::Resource.new("#{server}#{uri}", timeout).get
      metric_value = check_tasks(r)
      check_mesos_tasks(metric_value, mode, value, min, max)
    rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
      unknown  "Mesos #{server} is not responding"
    rescue RestClient::RequestTimeout
      unknown  "Mesos #{server} connection timed out"
    end
    ok "Found #{metric_value} tasks running"
  end

  # Redirects server call to discover the Leader
  # @param server [String] Server address
  # @param port [Number] api port
  # @return [Url] Url representing the Leader

  def get_leader_url(server, port)
    RestClient::Resource.new("http://#{server}:#{port}/redirect").get.request.url
  end

  # Parses JSON data as returned from Mesos  API
  # @param data [String] Server response
  # @return [Numeric] Number of running tasks

  def check_tasks(data)
    begin
      running_tasks = JSON.parse(data)[MesosRunningTaskCheck.metrics_name]
    rescue JSON::ParserError
      raise "Could not parse JSON response: #{data}"
    end

    if running_tasks.nil?
      raise "No tasks in server response: #{data}"
    end

    running_tasks.round
  end

  def check_mesos_tasks(metric_value, mode, value, min, max)
    if config[:delta]
      db = Daybreak::DB.new '/tmp/mesos-metrics.db', default: 0
      prev_value = db['task_running']
      db.lock do
        db['task_running'] = metric_value
      end
      metric_value -= prev_value
      db.flush
      db.compact
      db.close
    end
    case mode
    when 'eq'
      critical "The number of running tasks cluster is equal to #{value}!" if metric_value.equal? value
    when 'ne'
      critical "The number of running tasks cluster is not equal to #{value}!" if metric_value != value
    when 'lt'
      critical "The number of running tasks cluster is lower than #{value}!" if metric_value < value
    when 'gt'
      critical "The number of running tasks cluster is greater than #{value}!" if metric_value > value
    when 'rg'
      unless (min.to_i..max.to_i).cover? metric_value
        critical "The number of running tasks in cluster is not in #{min} - #{max} value range!"
      end
    end
  end
end

#! /usr/bin/env ruby
#
#   check-mesos-failed-tasks
#
# DESCRIPTION:
#   This plugin checks that there are less or same number of failed tasks than provided on a Mesos cluster
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

class MesosFailedTasksCheck < Sensu::Plugin::Check::CLI
  check_name 'CheckMesosFailedTasks'
  @metrics_name = 'master/tasks_failed'.freeze

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
    if config[:value].to_i < 0
      unknown 'Number of failed tasks cannot be negative'
    end

    server = config[:server]
    port = config[:port]
    uri = config[:uri]
    timeout = config[:timeout].to_i
    value = config[:value].to_i

    begin
      server = get_leader_url server, port
      r = RestClient::Resource.new("#{server}#{uri}", timeout).get
      tasks_failed = check_tasks(r)
      if config[:delta]
        db = Daybreak::DB.new '/tmp/mesos-metrics.db', default: 0
        prev_value = db["task_#{MesosFailedTasksCheck.metrics_name}"]
        db.lock do
          db["task_#{MesosFailedTasksCheck.metrics_name}"] = tasks_failed
        end
        tasks_failed -= prev_value
        db.flush
        db.compact
        db.close
      end

      if tasks_failed >= value
        critical "The number of FAILED tasks [#{tasks_failed}] is bigger than provided [#{value}]!"
      end
    rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound, SocketError
      unknown "Mesos #{server} is not responding"
    rescue RestClient::RequestTimeout
      unknown "Mesos #{server} connection timed out"
    end
    ok
  end

  # Redirects server call to discover the Leader
  # @param server [String] Server address
  # @param port [Number] api port
  # @return [Url] Url representing the Leader

  def get_leader_url(server, port)
    RestClient::Resource.new("http://#{server}:#{port}/redirect").get.request.url
  end

  # Parses JSON data as returned from Mesos's metrics API
  # @param data [String] Server response
  # @return [Integer] Number of failed tasks in Mesos
  def check_tasks(data)
    begin
      tasks_failed = JSON.parse(data)[MesosFailedTasksCheck.metrics_name]
    rescue JSON::ParserError
      raise "Could not parse JSON response: #{data}"
    end

    if tasks_failed.nil?
      raise "No metrics for [#{MesosFailedTasksCheck.metrics_name}] in server response: #{data}"
    end

    tasks_failed.round.to_i
  end
end

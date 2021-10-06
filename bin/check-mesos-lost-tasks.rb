#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-mesos-lost-tasks
#
# DESCRIPTION:
#   This plugin checks that there are less or same number of lost tasks than provided on a Mesos cluster
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

class MesosLostTasksCheck < Sensu::Plugin::Check::CLI
  check_name 'CheckMesosLostTasks'
  @metrics_name = 'master/tasks_lost'.freeze

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

  option :timeout,
         description: 'timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 5

  option :uri,
         description: 'Endpoint URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/metrics/snapshot'

  option :value,
         description: 'value to check against',
         short: '-v VALUE',
         long: '--value VALUE',
         default: 0,
         proc: proc(&:to_i),
         required: false

  option :delta,
         short: '-d',
         long: '--delta',
         description: 'Use this flag to compare the metric with the previously retreived value',
         boolean: true

  def run
    if config[:value].negative?
      unknown 'Number of lost tasks cannot be negative, please set --value to a number greater or equal to 0'
    end

    server = config[:server]
    port = config[:port]
    uri = config[:uri]
    timeout = config[:timeout]
    value = config[:value]

    begin
      server = get_leader_url server, port
      # remove comment for debugging purpose
      # puts(server)

      r = RestClient::Resource.new("#{server}#{uri}", timeout).get
      tasks_lost = check_tasks(r)
      if config[:delta]
        db = Daybreak::DB.new '/tmp/mesos-metrics.db', default: 0
        prev_value = db["task_#{MesosLostTasksCheck.metrics_name}"]
        db.lock do
          db["task_#{MesosLostTasksCheck.metrics_name}"] = tasks_lost
        end
        tasks_lost -= prev_value
        db.flush
        db.compact
        db.close
      end
      if tasks_lost >= value
        critical "The number of LOST tasks [#{tasks_lost}] is bigger than provided [#{value}]!"
      end
    end
    ok
  end

  def get_leader_url(server, port)
    RestClient::Resource.new("http://#{server}:#{port}/redirect").get.request.url
  end

  # Parses JSON data as returned from Mesos's metrics API
  # @param data [String] Server response
  # @return [Integer] Number of lost tasks in Mesos
  def check_tasks(data)
    begin
      tasks_lost = JSON.parse(data)[MesosLostTasksCheck.metrics_name]
    rescue JSON::ParserError
      raise "Could not parse JSON response: #{data}"
    end

    if tasks_lost.nil?
      raise "No metrics for [#{MesosLostTasksCheck.metrics_name}] in server response: #{data}"
    end

    tasks_lost.round.to_i
  end
end

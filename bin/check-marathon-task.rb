#!/usr/bin/env ruby
#
#   check-marathon-task
#
# DESCRIPTION:
#   This plugin checks that the given Mesos/Marathon task is running properly
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-marathon-task.rb -s mesos-a,mesos-b,mesos-c -p 8080 -t mywebsite -i 5
#   CheckMarathonTask OK: 5/5 mywebsite tasks running
#
#   check-marathon-task.rb -s mesos-a,mesos-b,mesos-c -p 8080 -t mywebsite -i 5
#   CheckMarathonTask CRITICAL: 3/5 mywebsite tasks running
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Antoine POPINEAU (antoine.popineau@appscho.com)
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'net/http'
require 'json'

# This plugin checks that the given Mesos/Marathon task is running properly.
#
# This means that all of the following is true:
# 1. There are N tasks for the app, as defined by the --instances parameter
# 2. Each task's state is running
# 3. No task is unhealthy, as defined in Marathon
#
# A task is seen as **unhealthy** by Marathon if any of the health checks for
# the task is not **alive**.  Alive means that a check has a last success that
# is more recent than last failure. It's not alive if the last failure is more
# recent than the last success, or if the last success doesn't exist at all.
class MarathonTaskCheck < Sensu::Plugin::Check::CLI
  check_name 'CheckMarathonTask'

  option :server, short: '-s SERVER', long: '--server SERVER', required: true
  option :port, short: '-p PORT', long: '--port PORT', default: 8080
  option :task, short: '-t TASK', long: '--task TASK', required: true
  option :instances, short: '-i INSTANCES', long: '--instances INSTANCES',
                     required: true, proc: proc(&:to_i)
  option :protocol, short: '-P PROTOCOL', long: '--protocol PROTOCOL',
                    required: false, default: 'http'
  option :username, short: '-u USERNAME', long: '--username USERNAME',
                    required: false
  option :password, long: '--password PASSWORD', required: false

  def run
    if config[:instances].zero?
      unknown 'number of instances should be an integer'
    end

    if !config[:username].nil? && config[:password].nil? ||
       config[:username].nil? && !config[:password].nil?
      unknown 'You must provide both username and password'
    end

    failures = []
    config[:server].split(',').each do |s|
      begin
        url = URI.parse("#{config[:protocol]}://#{s}:#{config[:port]}/v2/tasks?status=running")
        req = Net::HTTP::Get.new(url)
        req.add_field('Accept', 'application/json')
        if !config[:username].nil? && !config[:password].nil?
          req.basic_auth(config[:username], config[:password])
        end
        r = Net::HTTP.start(url.host, url.port,
                            use_ssl: config[:protocol] == 'https') do |h|
          h.request(req)
        end

        ok_count, unhealthy = check_tasks r.body

        message = "#{ok_count}/#{config[:instances]} #{config[:task]} tasks running"

        if unhealthy.any?
          message << ":\n" << unhealthy.join("\n")
        end

        if unhealthy.any? || ok_count < config[:instances]
          critical message
        end

        ok message
      rescue Errno::ECONNREFUSED, SocketError
        failures << "Marathon on #{s} could not be reached"
      rescue => err
        failures << "error caught trying to reach Marathon on #{s}: #{err}"
      end
    end

    unknown "marathon task state could not be retrieved:\n" << failures.join("\n")
  end

  # Parses JSON data as returned from Marathon's tasks API
  # @param data [String] Server response
  # @return [Numeric, [String]] Number of running tasks and a list of error
  #                             messages from unhealthy tasks
  def check_tasks(data)
    begin
      tasks = JSON.parse(data)['tasks']
    rescue JSON::ParserError
      raise "Could not parse JSON response: #{data}"
    end

    if tasks.nil?
      raise "No tasks in server response: #{data}"
    end

    tasks.select! do |t|
      t['appId'] == "/#{config[:task]}"
    end

    unhealthy = []

    # Collect last error message for all health checks that are not alive
    tasks.each do |task|
      checks = task['healthCheckResults'] || []
      checks.each do |check|
        if check['alive']
          next
        end
        message = check['lastFailureCause'] ||
                  'Health check not alive'
        unhealthy << message
      end
    end

    [tasks.length, unhealthy]
  end
end

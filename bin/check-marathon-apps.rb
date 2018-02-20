#!/usr/bin/env ruby
#
#   check-marathon-apps
#
# DESCRIPTION:
#   This plugin creates checks results for each Marathon app that is running, 
#   and reports the status of the app based on Marathon Application Status Reference.
#   https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-status-reference
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
#   check-marathon-apps.rb -s mesos-a,mesos-b,mesos-c -p 8080 -t mywebsite -i 5
#   CheckMarathonTask OK: 5/5 mywebsite tasks running
#
#   check-marathon-task.rb -s mesos-a,mesos-b,mesos-c -p 8080 -t mywebsite -i 5
#   CheckMarathonTask CRITICAL: 3/5 mywebsite tasks running
#
# NOTES:
#
# LICENSE:
#   Copyright 2018, Sensu Plugins
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

# This plugin checks that the given Mesos/Marathon task is running properly.
#
# This means that all of the following is true:
# 1. There are N tasks for the app, as defined by the --instances parameter or checks configured tasks in Marathon as fallback
# 2. Each task's state is running
# 3. No task is unhealthy, as defined in Marathon
#
# A task is seen as **unhealthy** by Marathon if any of the health checks for
# the task is not **alive**.  Alive means that a check has a last success that
# is more recent than last failure. It's not alive if the last failure is more
# recent than the last success, or if the last success doesn't exist at all.
class MarathonAppsCheck < Sensu::Plugin::Check::CLI
  check_name 'CheckMarathonApps'

  option :url,
    description: 'Marathon API URL',
    short: '-u url',
    long: '--url url',
    default: 'http://localhost:8080'

  option :username,
    short: '-u USERNAME',
    long: '--username USERNAME',
    default: '',
    required: false,
    description: 'Marathon API username'

  option :password,
    long: '--password PASSWORD',
    default: '',
    required: false,
    description: 'Marathon API password'

  option :match_pattern,
    short: '-m PATTERN',
    long: '--match-pattern PATTERN',
    required: false,
    description: "Match app names against a pattern"

  option :exclude_pattern,
    short: '-x PATTERN',
    long: '--exclude-pattern PATTERN',
    required: false,
    description: "Exclude apps that match a pattern"

  option :marathon_keys,
    long: '--marathon-keys KEY1,KEY2,KEY3',
    default: 'id,version,versionInfo,tasksStaged,tasksRunning,tasksHealthy,tasksUnhealthy,lastTaskFailure',
    required: false,
    description: 'Keys retrieved from Marathon API that will be included in the output',
    proc: proc { |a| a.split(',') }

  option :default_check_config,
    long: '--default-check-config "{"status":{"running":{"valid":"json"}},"health":{"healthy":{"valid":"json"}}}"',
    default: '{"status":{"delayed":{"status": 1},"waiting":{"status": 1},"suspended":{"status": 1},"deploying":{"status": 1},"running":{"status": 0}},"health":{"unscheduled":{"status": 2},"overcapacity":{"status": 1},"unknown":{"status": 3},"staged":{"status": 1},"unhealthy":{"status": 2},"healthy":{"status": 0}}}',
    required: false,
    description: 'Default values to be used while creating the check results, it can also be retrieved from the Marathon app ENV definition. Example: SENSU_MARATHON_STATUS_RUNNING_STATUS=0 SENSU_MARATHON_HEALTH_HEALTHY_STATUS=0'

  option :sensu_client_url,
    description: 'Sensu client HTTP URL socket',
    long: '--sensu-client-url url',
    default: 'http://localhost:3031'

  option :timeout,
    description: 'timeout in seconds',
    short: '-T TIMEOUT',
    long: '--timeout TIMEOUT',
    proc: proc(&:to_i),
    default: 5

  def run
    if !config[:username].nil? && config[:password].nil? ||
        config[:username].nil? && !config[:password].nil?
      unknown 'You must provide both username and password'
    end

    apps = get_apps
    queue = get_queue

    apps.keep_if {|app| app['id'][/#{config['match_pattern']}/] } if config['match_pattern']
    apps.delete_if {|app| app['id'][/#{config[:exclude_pat]}/] } if config[:exclude_pat]

    apps.each do |app|
      # queue must be filtered before reaching this point and should only contain items that matches app['id']
      app_queue =  queue.select {|q| q['app']['id'][/^#{app['id']}$/]}
      check_result = check_result_scaffold(app)

      check_config = parse_json(config['default_check_config'])
      check_config.merge(get_env_check_config(app['env']))

      check_result['marathon']['status'] = get_marathon_app_status(app, app_queue)
      check_result['marathon']['health'] = get_marathon_app_health(app)

      %w[health status].each do |reference|
        check_result['name'] = "check_marathon_app_#{reference}#{app['id'].gsub('/','_')}"
        check_result['output'] = "Check #{reference.upcase} #{check_result['marathon'][reference].capitalize} - "\
          "tasksRunning(#{app['tasksRunning'].to_i}), tasksStaged(#{app['tasksStaged'].to_i}), "\
          "tasksHealthy(#{app['tasksHealthy'].to_i}), tasksUnhealthy(#{app['tasksUnhealthy'].to_i})"
        check_result['status'] = check_config[reference]['status']
        post_check_result(check_result)
      end
    end
  end

  def check_result_scaffold(app)
    {
      name: '',
      executed: Time.now.to_i,
      marathon: app.select {|k,v| config['marathon_keys'].include?(k)},
      source: 'marathon',
      output: '',
      status: 3
    }
  end

  def get(path)
    begin
      RestClient.get("#{config[:url]}#{path}", user: config[:username], password: config[:password], accept: 'application/json', timeout: 10).body
    rescue RestClient::ExceptionWithResponse => e
      critical "Error while trying to GET (#{config[:url]}#{path}): #{e.response}"
    rescue => e
      critical "Failed to reach #{config[:url]}#{path} due to: #{e}"
    end
  end

  def get_apps
    # http://mesosphere.github.io/marathon/api-console/index.html
    parse_json(get('/v2/apps?embed=apps.tasks&embed=apps.count&embed=apps.deployments&embed=apps.lastTaskFailure&embed=apps.failures&embed=apps.taskStats'))['apps']
  end

  def get_queue
    # http://mesosphere.github.io/marathon/api-console/index.html
    parse_json(get('/v2/queue'))['queue']
  end

  def post_check_result(data)
    begin
      RestClient.post("#{config['sensu_client_url']}/results", data, content_type: 'application/json', timeout: config['timeout'])
    rescue RestClient::ExceptionWithResponse => e
      critical "Error while trying to POST check result (#{config['sensu_client_url']}/results): #{e.response}"
    rescue => e
      critical "Failed to reach #{config['sensu_client_url']}/results due to: #{e}"
    end
  end

  def parse_json(json)
    begin
      JSON.parse(json)
    rescue JSON::ParserError => e
      critical "Failed to parse JSON: #{e}\nJSON => #{json}"
    end
  end

  def get_env_check_config(app_envs)
    config = {}

    # Only grab env that starts with SENSU_MARATHON
    envs = app_envs.select {|e| /^SENSU_MARATHON/.match(e)}

    envs.each do |env, value|
      config_keys = env.split('_')

      # Delete SENSU and MARATHON element
      config_keys.delete_if {|k| /^SENSU$|^MARATHON$/.match(k)}

      # Downcase
      config_keys.map!(&:downcase)

      # Convert config_keys into nested hash keys
      conf  = array.reverse.inject(value) { |a, b| { b: a } }
      config.merge!(conf)
    end
    return config
  end

  def get_marathon_app_status(app, queue)
    # https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-status-reference
    if queue['delay']['overdue'] == true
      'waiting'
    elsif queue['delay']['overdue'] == false
      'delayed'
    elsif app['instances'].to_i.zero? and app['tasksRunning'].to_i.zero?
      'suspended'
    elsif app['deployments'].to_a.length > 0
      'deploying'
    elsif app['instances'].to_i == app['tasksRunning'].to_i
      'running'
    else
      ''
    end
  end

  def get_marathon_app_health(app)
    # https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-health-reference
    if apps[0]['tasks'].to_a.length.zero? and apps[0]['deployments'].to_a.length.zero?
      'unscheduled'
    elsif app['instances'].to_i < app['tasksRunning'].to_i
      'overcapacity'
    elsif app['tasksStaged'].to_i > 0
      'staged'
    elsif app['healthChecks'].to_a.length.zero?
      'unknown'
    elsif app['tasksUnhealthy'].to_i > 0
      'unhealthy'
    elsif app['healthChecks'].to_a.length > 0 and app['tasksHealthy'].to_i > 0
      'healthy'
    else
      ''
    end
  end
end

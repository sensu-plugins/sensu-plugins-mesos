#!/opt/sensu/embedded/bin/ruby
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
#   Exclude apps matching "test"
#   check-marathon-apps.rb -x test
#   CheckMarathonApps OK: Marathon Apps Status and Health check is running properly
#
#   Only apps matching "test"
#   check-marathon-task.rb -i test
#   CheckMarathonApps OK: Marathon Apps Status and Health check is running properly
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

# This plugin checks Marathon apps based on https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-status-reference
#
# It produces a check result for `health` and another check result for `status`
# Check results can be customised by providing default values on '--default-check-config JSON' or by populating Marathon app labels, example:
# SENSU_MARATHON_STATUS_UNSCHEDULED_TTL = 10
# SENSU_MARATHON_STATUS_UNSCHEDULED_SOURCE = my_source
#
# Those labels will override the default values and create the following check result if the status is Unscheduled:
# {
#   "name": "check_marathon_app_test_status",
#   "executed": 1519305736,
#   "marathon": {
#     "id": "/test",
#     "version": "2018-02-20T15:09:43.086Z",
#     "versionInfo": {
#       "lastScalingAt": "2018-02-20T15:09:43.086Z",
#       "lastConfigChangeAt": "2018-02-20T15:09:43.086Z"
#     },
#     "tasksStaged": 0,
#     "tasksRunning": 1,
#     "tasksHealthy": 1,
#     "tasksUnhealthy": 0
#   },
#   "source": "my_source",
#   "output": "STATUS Unscheduled - tasksRunning(1), tasksStaged(0), tasksHealthy(1), tasksUnhealthy(0)",
#   "ttl": 10,
#   "status": 0
# }
#
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
    description: 'Match app names against a pattern'

  option :exclude_pattern,
    short: '-x PATTERN',
    long: '--exclude-pattern PATTERN',
    required: false,
    description: 'Exclude apps that match a pattern'

  option :marathon_keys,
    long: '--marathon-keys KEY1,KEY2,KEY3',
    default: 'id,version,versionInfo,tasksStaged,tasksRunning,tasksHealthy,tasksUnhealthy,lastTaskFailure',
    required: false,
    description: 'Keys retrieved from Marathon API that will be included in the output'

  option :default_check_config,
    long: '--default-check-config "{"status":{"running":{"valid":"json"}},"health":{"healthy":{"valid":"json"}}}"',
    default: '{"status":{"delayed":{"status": 1},"waiting":{"status": 1},"suspended":{"status": 1},"deploying":{"status": 1},'\
    '"running":{"status": 0}},"health":{"unscheduled":{"status": 2},"overcapacity":{"status": 1},'\
    '"unknown":{"status": 3},"staged":{"status": 1},"unhealthy":{"status": 2},"healthy":{"status": 0}}}',
    required: false,
    description: 'Default values to be used while creating the check results, it can also be retrieved from the Marathon app labels definition.'\
    'Example: SENSU_MARATHON_STATUS_RUNNING_STATUS=0 SENSU_MARATHON_HEALTH_HEALTHY_STATUS=0'

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
    if !config[:username].nil? && config[:password].nil? || config[:username].nil? && !config[:password].nil?
      unknown 'You must provide both username and password to authenticate on Marathon API'
    end

    # Get Marathon API apps
    apps = fetch_apps

    # Get Marathon API queue
    queue = fetch_queue

    # Parse default check config
    check_config = parse_json(config[:default_check_config])
    # check_config.merge!(settings['marathon_app']['config'])

    # Filter apps
    apps.keep_if { |app| app['id'][/#{config[:match_pattern]}/] } if config[:match_pattern]
    apps.delete_if { |app| app['id'][/#{config[:exclude_pat]}/] } if config[:exclude_pat]

    apps.each do |app|
      # Select app queue if any
      app_queue = queue.select { |q| q['app']['id'][/^#{app['id']}$/] }.to_a.first

      # Build check result
      check_result = check_result_scaffold(app)

      # Parse Marathon app labels
      labels_config = parse_app_labels(app['labels'].to_h)

      %w[health status].each do |reference|
        # / is and invalid character
        check_result['name'] = "check_marathon_app#{app['id'].tr('/', '_')}_#{reference}"

        condition = case reference
                    when 'health'
                      get_marathon_app_health(app)
                    when 'status'
                      get_marathon_app_status(app, app_queue.to_h)
                    end

        # Merge user provided check config
        check_result.merge!(check_config.dig(reference, condition).to_h)

        # Merge Marathon parsed check config
        check_result.merge!(labels_config.dig(reference, condition).to_h)

        # Build check result output
        check_result['output'] = "#{reference.upcase} #{condition.capitalize} - "\
          "tasksRunning(#{app['tasksRunning'].to_i}), tasksStaged(#{app['tasksStaged'].to_i}), "\
          "tasksHealthy(#{app['tasksHealthy'].to_i}), tasksUnhealthy(#{app['tasksUnhealthy'].to_i})"

        # Make sure that check result data types are correct
        sanitize_check_result(check_result)

        # Send the result to sensu-client HTTP socket
        post_check_result(check_result)
      end
    end

    ok 'Marathon Apps Status and Health check is running properly'
  end

  def check_result_scaffold(app)
    {
      'name' => '',
      'executed' => Time.now.to_i,
      'marathon' => app.select { |k, _| config[:marathon_keys].split(',').include?(k) },
      'source' => 'marathon',
      'output' => '',
      'status' => 3
    }
  end

  def sanitize_check_result(check_result)
    # Force data types of different fields on the check result
    # https://sensuapp.org/docs/latest/reference/checks.html#example-check-definition
    # https://sensuapp.org/docs/latest/reference/checks.html#check-result-specification
    check_result.each do |k, v|
      if %w[publish standalone auto_resolve force_resolve handle truncate_output].include?(k)
        # Boolean
        check_result[k] = v.to_s.eql?('true')
      elsif %w[status interval issued executed timeout ttl ttl_status low_flap_threshold high_flap_threshold truncate_output_length].include?(k)
        # Integer
        check_result[k] = Integer(v)
      elsif %w[subscribers handlers aggregates].include?(k)
        # Array
        check_result[k] = Array(v.split(','))
      end
    end
  end

  def get(path)
    RestClient.get("#{config[:url]}#{path}",
                   user: config[:username],
                   password: config[:password],
                   accept: 'application/json',
                   timeout: config[:timeout]).body
  rescue RestClient::ExceptionWithResponse => e
    critical "Error while trying to GET (#{config[:url]}#{path}): #{e.response}"
  end

  def fetch_apps
    # http://mesosphere.github.io/marathon/api-console/index.html
    parse_json(get('/v2/apps?embed=apps.tasks&embed=apps.count&embed=apps.deployments'\
                   '&embed=apps.lastTaskFailure&embed=apps.failures&embed=apps.taskStats'))['apps']
  end

  def fetch_queue
    # http://mesosphere.github.io/marathon/api-console/index.html
    parse_json(get('/v2/queue'))['queue']
  end

  def post_check_result(data)
    RestClient.post("#{config[:sensu_client_url]}/results", data.to_json, content_type: 'application/json', timeout: config[:timeout])
  rescue RestClient::ExceptionWithResponse => e
    critical "Error while trying to POST check result (#{config[:sensu_client_url]}/results): #{e.response}"
  end

  def parse_json(json)
    JSON.parse(json.to_s)
  rescue JSON::ParserError => e
    critical "Failed to parse JSON: #{e}\nJSON => #{json}"
  end

  def parse_app_labels(app_labels)
    config = {}
    # Only grab labels that starts with SENSU_MARATHON
    labels = app_labels.to_h.select { |e| /^SENSU_MARATHON/.match(e) }

    labels.each do |label, value|
      config_keys = label.split('_')

      # Delete SENSU and MARATHON element
      config_keys.delete_if { |k| /^SENSU$|^MARATHON$/.match(k) }

      # Downcase
      config_keys.map!(&:downcase)

      # Add nested keys and value
      config[config_keys[0]] = {} unless config[config_keys[0]]
      config[config_keys[0]][config_keys[1]] = {} unless config[config_keys[0]][config_keys[1]]
      config[config_keys[0]][config_keys[1]][config_keys[2]] = value
    end
  end

  def get_marathon_app_status(app, app_queue)
    # https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-status-reference
    if app_queue.to_h.dig('delay', 'overdue') == true
      'waiting'
    elsif app_queue.to_h.dig('delay', 'overdue') == false
      'delayed'
    elsif app['instances'].to_i.zero? && app['tasksRunning'].to_i.zero?
      'suspended'
    elsif app['deployments'].to_a.any?
      'deploying'
    elsif app['instances'].to_i == app['tasksRunning'].to_i
      'running'
    else
      ''
    end
  end

  def get_marathon_app_health(app)
    # https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-health-reference
    if app['tasks'].to_a.length.zero? && app['deployments'].to_a.length.zero?
      'unscheduled'
    elsif app['instances'].to_i < app['tasksRunning'].to_i
      'overcapacity'
    elsif app['tasksStaged'].to_i > 0
      'staged'
    elsif app['healthChecks'].to_a.empty?
      'unknown'
    elsif app['tasksUnhealthy'].to_i > 0
      'unhealthy'
    elsif app['healthChecks'].to_a.any? && app['tasksHealthy'].to_i > 0
      'healthy'
    else
      ''
    end
  end
end

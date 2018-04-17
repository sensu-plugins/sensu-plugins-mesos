require_relative './spec_helper.rb'
require_relative '../bin/check-marathon-apps.rb'
require_relative './fixtures.rb'

# rubocop:disable Style/ClassVars
class MarathonAppsCheck
  attr_reader :check_results

  def initialize
    super
    @check_results = []
  end

  at_exit do
    @@autorun = false
  end

  def fetch_apps(*)
    JSON.parse(marathon_apps_with_embeds)
  end

  def fetch_queue(*)
    JSON.parse(marathon_queue)
  end

  def post_check_result(res)
    # simulate failure from sensu agent, see the overridden method in MarathonAppsCheck
    if res['name'] =~ /non-sensu-compliant-test/
      false
    else
      @check_results.push(res.dup)
      true
    end
  end

  def critical(*args)
    @status = 'CRITICAL'
    output(*args)
  end
end

describe 'MarathonTaskCheck' do
  before do
    @check = MarathonAppsCheck.new
  end

  matcher :contain_hash_with_keys do |keys|
    match do |hash_array|
      hash_array.any? { |hash| hash.merge(keys) == hash }
    end
  end

  describe '#run' do
    it 'tests multiple applications with different states' do
      expect { @check.run }.to output("CheckMarathonApps CRITICAL: 1 apps are failed to be reported to sensu\n").to_stdout

      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test_health',
        'output' => 'HEALTH Unknown - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 0,
        'aggregate' => 'health_aggregate'
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test_status',
        'output' => 'STATUS Running - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 0,
        'aggregate' => 'test'
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-running-healthy_health',
        'output' => 'HEALTH Healthy - tasksRunning(1), tasksStaged(0), tasksHealthy(1), tasksUnhealthy(0)',
        'status' => 0
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-running-healthy_status',
        'output' => 'STATUS Running - tasksRunning(1), tasksStaged(0), tasksHealthy(1), tasksUnhealthy(0)',
        'status' => 0
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-unhealthy_health',
        'output' => 'HEALTH Unhealthy - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(1)',
        'status' => 2
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-unhealthy_status',
        'output' => 'STATUS Running - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(1)',
        'status' => 0
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-suspended_health',
        'output' => 'HEALTH Unscheduled - tasksRunning(0), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 2
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-suspended_status',
        'output' => 'STATUS Suspended - tasksRunning(0), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 1
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-deploying_health',
        'output' => 'HEALTH  - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 3
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-deploying_status',
        'output' => 'STATUS Deploying - tasksRunning(1), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 1
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-delayed_health',
        'output' => 'HEALTH Unscheduled - tasksRunning(0), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 2
      )
      expect(@check.check_results).to contain_hash_with_keys(
        'name' => 'check_marathon_app_sensu-test-delayed_status',
        'source' => 'marathon',
        'output' => 'STATUS Delayed - tasksRunning(0), tasksStaged(0), tasksHealthy(0), tasksUnhealthy(0)',
        'status' => 1
      )
    end
  end
end

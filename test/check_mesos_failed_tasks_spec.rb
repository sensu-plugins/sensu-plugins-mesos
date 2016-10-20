require_relative './spec_helper.rb'
require_relative '../bin/check-mesos-failed-tasks.rb'
require_relative './fixtures.rb'

require 'sensu-plugin/check/cli'

# rubocop:disable Style/ClassVars
class MesosFailedTasksCheck
  at_exit do
    @@autorun = false
  end

  def critical(*); end

  def warning(*); end

  def ok(*); end

  def unknown(*); end
end

def check_results(parameters)
  check = MesosFailedTasksCheck.new parameters.split(' ')
  check.check_tasks(mesos_metrics_response)
end

describe 'MesosFailedTasksCheck' do
  before do
    @default_parameters = '--server localhost --value 0'
    @check = MesosFailedTasksCheck.new @default_parameters.split(' ')
  end

  describe '#run' do
    it 'tests that a failed tasks metrics are ok' do
      tasks_failed = check_results '--server localhost --value 4388'
      expect(tasks_failed).to be 4388
    end

    it 'tests that an empty server response raises an error' do
      expect { @check.check_tasks '{}' }.to raise_error(/No metrics for/)
      expect { @check.check_tasks '' }.to raise_error(/Could not parse JSON/)
    end
  end
end

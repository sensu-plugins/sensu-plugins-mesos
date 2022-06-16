# frozen_string_literal: true

require_relative './spec_helper.rb'
require_relative '../bin/check-mesos-lost-tasks.rb'
require_relative './fixtures.rb'

# rubocop:disable Style/ClassVars
class MesosLostTasksCheck
  at_exit do
    @@autorun = false
  end

  def critical(*); end

  def warning(*); end

  def ok(*); end

  def unknown(*); end
end

def check_results(parameters)
  check = MesosLostTasksCheck.new parameters.split(' ')
  check.check_tasks(mesos_metrics_response)
end

describe 'MesosLostTasksCheck' do
  before do
    @default_parameters = '--server localhost --value 0'
    @check = MesosLostTasksCheck.new @default_parameters.split(' ')
  end

  describe '#run' do
    it 'tests that a lost tasks metrics are ok' do
      tasks_lost = check_results '--server localhost --value 42'
      expect(tasks_lost).to be 42
    end

    it 'tests that an empty server response raises an error' do
      expect { @check.check_tasks '{}' }.to raise_error(/No metrics for/)
      expect { @check.check_tasks '' }.to raise_error(/Could not parse JSON/)
    end
  end
end
# rubocop:enable Style/ClassVars

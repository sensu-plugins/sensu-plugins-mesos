# frozen_string_literal: true

require_relative './spec_helper.rb'
require_relative '../bin/check-marathon-task.rb'
require_relative './fixtures.rb'

# rubocop:disable Style/ClassVars
class MarathonTaskCheck
  at_exit do
    @@autorun = false
  end

  def critical(*); end

  def warning(*); end

  def ok(*); end

  def unknown(*); end
end

def check_results(parameters)
  check = MarathonTaskCheck.new parameters.split(' ')
  check.check_tasks marathon_response
end

describe 'MarathonTaskCheck' do
  before do
    @default_parameters = '--server localhost --task foo/bar --instances 1'
    @check = MarathonTaskCheck.new @default_parameters.split(' ')
  end

  describe '#run' do
    it 'tests that a single running task is ok' do
      tasks_ok, unhealthy = check_results @default_parameters
      expect(tasks_ok).to be 1
      expect(unhealthy).to be == []
    end

    it 'counts tasks correctly' do
      tasks_running, unhealthy = check_results '--server s --task non/existing --instances 1'
      expect(tasks_running).to be 0
      expect(unhealthy).to be == []
    end

    it 'does not count unhealthy tasks' do
      tasks_running, unhealthy = check_results '--server s --task broken/app --instances 1'
      expect(tasks_running).to be 2
      expect(unhealthy.count).to eq 2
    end

    it 'tests that an empty server response raises an error' do
      expect { @check.check_tasks '{}' }.to raise_error(/No tasks/)
      expect { @check.check_tasks '' }.to raise_error(/Could not parse JSON/)
    end
  end
end
# rubocop:enable Style/ClassVars

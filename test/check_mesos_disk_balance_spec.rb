require_relative './spec_helper.rb'
require_relative '../bin/check-mesos-disk-balance.rb'
require_relative './fixtures.rb'

require 'sensu-plugin/check/cli'

# rubocop:disable Style/ClassVars
class MesosDiskBalanceCheck
  at_exit do
    @@autorun = false
  end

  def critical(*); end

  def warning(*); end

  def ok(*); end

  def unknown(*); end
end

def check_results(parameters)
  check = MesosDiskBalanceCheck.new parameters.split(' ')
  check.get_check_diff(check.get_slaves(mesos_slave_response))
end

describe 'MesosDiskBalanceCheck' do
  before do
    @default_parameters = '--server localhost --critical 0'
    @check = MesosDiskBalanceCheck.new @default_parameters.split(' ')
  end

  describe '#run' do
    it 'tests that a failed tasks metrics are ok' do
      cpu_diff = check_results '--server localhost --critical 10'
      expect(cpu_diff['diff']).to be 1
    end

    it 'tests that an empty server response raises an error' do
      expect { @check.get_slaves '{}' }.to raise_error(/No metrics for/)
      expect { @check.get_slaves '' }.to raise_error(/Could not parse JSON/)
    end
  end
end
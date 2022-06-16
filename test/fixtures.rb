# frozen_string_literal: true

def marathon_response
  File.read File.join(__dir__, 'fixtures', __method__.to_s + '.json')
end

def mesos_metrics_response
  File.read File.join(__dir__, 'fixtures', __method__.to_s + '.json')
end

def mesos_slave_response
  File.read File.join(__dir__, 'fixtures', __method__.to_s + '.json')
end

def marathon_apps_with_embeds
  File.read File.join(__dir__, 'fixtures', __method__.to_s + '.json')
end

def marathon_queue
  File.read File.join(__dir__, 'fixtures', __method__.to_s + '.json')
end

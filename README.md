## Sensu-Plugins-mesos

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-mesos.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-mesos)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-mesos.svg)](http://badge.fury.io/rb/sensu-plugins-mesos)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-mesos.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-mesos)

## Functionality

## Files
 * bin/check-chronos.rb
 * bin/check-metronome.rb
 * bin/check-marathon.rb
 * bin/check-marathon-apps.rb
 * bin/check-mesos.rb
 * bin/check-mesos-cpu-balance.rb
 * bin/check-mesos-disk-balance.rb
 * bin/check-mesos-gpu-balance.rb
 * bin/check-mesos-mem-balance.rb
 * bin/metrics-marathon.rb
 * bin/metrics-mesos.rb

## Usage

### bin/check-marathon-apps.rb

Note: This check is an unconventional one. It won't output a check result as many
other conventional check scripts, and will publish multiple check results via
the local sensu agent endpoint, effectively breaks the expectation of 1:1
mapping between check-definition and check-results.

This plugin checks Marathon apps based on
https://mesosphere.github.io/marathon/docs/marathon-ui.html#application-status-reference .
It produces two check results per application. One for the apps `health` and
another check result for the apps `status`.

Check results can be customised by two ways:

1. Default check result fields thats applied to all will be provided by a
   default check config. Please see th esource code to see the whole defaults.
2. Application owners can override check results by using marathon labels. This
   allows each application to have different fields in the published result.
   e.g. per app escalation or aggregate can be controlled by applying Marathon
   labels to the apps.

```
SENSU_MARATHON_CONTACT = team_a_rotation
SENSU_MARATHON_AGGREGATE = this_apps_aggregate  # will be applied to both `status` and `health` check results
SENSU_MARATHON_STATUS_AGGREGATE = status_aggregate  # status result of the app have different aggregate
SENSU_MARATHON_HEALTH_AGGREGATE = health_aggregate  # health result of the app have different aggregate
SENSU_MARATHON_STATUS_UNSCHEDULED_STATUS = 0  # Disable the check's fail status for this app when it's in unscheduled state.
```

The override templates that could be used in marathon app labels are:

```
SENSU_MARATHON_<check_result_field>  # will be applied all below if not overridden
SENSU_MARATHON_STATUS_<check_result_field>  # will be applied all status states if not overridden
SENSU_MARATHON_STATUS_<status_state>_<check_result_field>
SENSU_MARATHON_HEALTH_<check_result_field>  # will be applied all healt states if not overridden
SENSU_MARATHON_RESULT_<result_state>_<check_result_field>
```

Where:
* `check_result_field` could be any field in json.
* `status_state` is one of "waiting", "delayed", "suspended", "deploying" or "running".
* `health_state` is one of "unscheduled", "overcapacity", "staged", "unknown", "unhealthy" or "healthy".

Example run:

```
$ check-marathon-task.rb
heckMarathonApps OK: Marathon Apps Status and Health check is running properly
```

The command output of the check script will always be same independently from
which apps are being checked, but you'll see 2 check-results per app like these
in sensu:

```
{
  "name": "check_marathon_app_test_status",
  "executed": 1519305736,
  "marathon": {
    "id": "/test",
    "version": "2018-02-20T15:09:43.086Z",
    "versionInfo": {
      "lastScalingAt": "2018-02-20T15:09:43.086Z",
      "lastConfigChangeAt": "2018-02-20T15:09:43.086Z"
    },
    "tasksStaged": 0,
    "tasksRunning": 1,
    "tasksHealthy": 1,
    "tasksUnhealthy": 0
  },
  "output": "STATUS Unscheduled - tasksRunning(1), tasksStaged(0), tasksHealthy(1), tasksUnhealthy(0)",
  "ttl": 10,
  "source": "marathon",
  "status": 2
}
{
  "name": "check_marathon_app_test_health",
  "executed": 1519305736,
  "marathon": {
    "id": "/test",
    "version": "2018-02-20T15:09:43.086Z",
    "versionInfo": {
      "lastScalingAt": "2018-02-20T15:09:43.086Z",
      "lastConfigChangeAt": "2018-02-20T15:09:43.086Z"
    },
    "tasksStaged": 0,
    "tasksRunning": 1,
    "tasksHealthy": 1,
    "tasksUnhealthy": 0
  },
  "output": "HEALTH Healthy - tasksRunning(1), tasksStaged(0), tasksHealthy(1), tasksUnhealthy(0)",
  "ttl": 10,
  "source": "marathon",
  "status": 0
}
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes

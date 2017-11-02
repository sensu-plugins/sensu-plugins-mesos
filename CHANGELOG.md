# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
- check-marathon-task.rb: solved a bug which prevented to alert when number of instances were retrieved from Marathon

## [2.1.0] - 2017-10-20
### Changed
- check-marathon-task.rb: if instances are not defined, plugin will check number of configured instances in Marathon. Also removed Net::HTTP in favour of Restclient::Resource

## [2.0.0] - 2017-07-15
### Added
- Ruby 2.3.0 testing
- Ruby 2.4.1 testing

### Breaking Changes
- Drop Ruby 1.9.3 support

### [1.1.0] - 2017-07-10
### Added
- metrics-mesos.rb: Added option "include_role" to inject in metric fields whether a master node is leader or standby

## [1.0.0] - 2017-05-05
### Breaking Change
- check-mesos.rb: removed the `mode` parameter (@luisdavim)

### Added
- check-metronome.rb: Check if Metronome is running (@luisdavim)
- check-mesos-cpu-balance.rb: Check for imballanced use of CPU accross mesos agents (@luisdavim)
- check-mesos-gpu-balance.rb: Check for imballanced use of GPU accross mesos agents (@luisdavim)
- check-mesos-disk-balance.rb: Check for imballanced use of disk accross mesos agents (@luisdavim)
- check-mesos-mem-balance.rb: Check for imballanced use of memory accross mesos agents (@luisdavim)

### Changed
- check-marathon-task.rb: Use the health check results to verify that a task is running. (@andrelaszlo)
- check-marathon-task.rb: Rename incorrect "state" parameter to "status". (@andrelaszlo)
- Add https support and authentication to marathon plugins: (thanks to Erasys GmbH)
    - Add "protocol" option to check-marathon and metrics-marathon
    - Add "protocol", "username" and "password" options to check-marathon-task
- All checks now have a configurable API endpoint using --uri or -u (@luisdavim)
- Support the latest Mesos API (@luisdavim)
- Dropped support for Ruby 1.9.3 (@luisdavim)

## [0.1.1] - 2016-03-04
### Added
- metrics-mesos.rb, metrics-marathon.rb: add port option

### Changed
- Rubocop upgrade and cleanup

## [0.1.0] - 2015-09-14
### Added
- Added a check comparing Marathon instances for a specific task against the configured minimum

## [0.0.4] - 2015-07-30
### Changed
- Mesos check supports multiple servers.
- Updated Rubocop to `0.32.1`
- Updated documentation links in README and CONTRIBUTING
- Removed unused tasks from the Rakefile
- Set all deps to alpha order

### Added
- Basic chronos check.

### Fixed
- Only create binstubs for Ruby scripts

## [0.0.2] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

### Added
- Timeout option.

## 0.0.1 - 2015-05-21
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/2.1.0...HEAD
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.1.1...1.0.0
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.2...0.0.4
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.1...0.0.2

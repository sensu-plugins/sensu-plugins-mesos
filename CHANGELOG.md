#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
- check-marathon-task.rb: Use the health check results to verify that a task is running.
- check-marathon-task.rb: Rename incorrect "state" parameter to "status".
- Add https support and authentication to marathon plugins: (thanks to Erasys GmbH)
    - Add "protocol" option to check-marathon and metrics-marathon
    - Add "protocol", "username" and "password" options to check-marathon-task

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.1.1...HEAD
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.2...0.0.4
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-mesos/compare/0.0.1...0.0.2

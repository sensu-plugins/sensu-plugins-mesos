## Sensu-Plugins-mesos

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-mesos.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-mesos)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-mesos.svg)](http://badge.fury.io/rb/sensu-plugins-mesos)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-mesos.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-mesos)
## Functionality

## Files
 * bin/check-marathon
 * bin/check-mesos
 * bin/metrics-marathon
 * bin/metrics-mesos

## Usage

## Installation

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-mesos -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-mesos`

#### Bundler

Add *sensu-plugins-disk-checks* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-mesos' do
  options('--prerelease')
  version '0.0.1.alpha.4'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-mesos' do
  options('--prerelease')
  version '0.0.1.alpha.4'
end
```

## Notes

[1]:[https://travis-ci.org/sensu-plugins/sensu-plugins-mesos]
[2]:[http://badge.fury.io/rb/sensu-plugins-mesos]
[3]:[https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos]
[4]:[https://codeclimate.com/github/sensu-plugins/sensu-plugins-mesos]
[5]:[https://gemnasium.com/sensu-plugins/sensu-plugins-mesos]

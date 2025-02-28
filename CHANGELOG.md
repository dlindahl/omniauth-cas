# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/) and this
project adheres to [Semantic Versioning](https://semver.org/)

## 3.0.1 - 2025-02-28

* Prefer `require_relative` over `require`
* Remove redundant require of `net/https`

## 3.0.0 - 2024-02-24

### Changed

* There are no changes between 3.0.0 and 3.0.0.beta.1

## 3.0.0.beta.1 - 2024-01-12

### Changed

* Breaking change: Support OmniAuth 2 (#82).
* Potential breaking change: case of `Omniauth::Cas::VERSION` module (#76).

### Removed

* Compatibility with EOL Ruby versions (#73).

## 2.0.0 - 2010-11-14

### Added

* Add support for multivalued attributes ([#59](https://github.com/dlindahl/omniauth-cas/pull/59))
* Successfully test against Ruby 2.4 and up ([#60](https://github.com/dlindahl/omniauth-cas/pull/60))

### Changed

* Forward success response to `fetch_raw_info` callback ([#51](https://github.com/dlindahl/omniauth-cas/pull/51))
* Relax development dependencies to the latest versions

## 1.1.1 - 2016-09-19

### Changed

* Relax gemspec requirements, to add support for Rails 5.

Note that the only tested versions of Ruby are now 2.1, 2.2, and 2.3 - older
versions of Ruby should work, but are no longer officially supported.

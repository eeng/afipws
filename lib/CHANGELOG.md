# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - 2020-10-28

### Added

- Long overdue CHANGELOG file.
- Include `httpclient` dependency so we can wrap network errors.

### Changed

- Rename Afipws::WSError to Afipws::Error, and create subclasses to distinguish between different types of errors.

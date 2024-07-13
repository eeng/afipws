# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.3.0] - 2024-07-13

- Upgrade Ruby to 3.3.4
- Upgrade Savon to 2.15.1

## [2.2.0] - 2023-03-19

- Handle Savon::HTTPError

## [2.0.0] - 2020-10-28

- Long overdue CHANGELOG file.
- Include `httpclient` dependency so we can wrap network errors.
- Rename `Afipws::WSError` to `Afipws::Error`, and create subclasses to distinguish between different types of errors.

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/),
and this project adheres to [Semantic Versioning](https://semver.org/).

*Labels: Added // Changed // Deprecated // Removed // Fixed // Security // Chore*

## [Unreleased]
...

## [5.1.2] - 2023-06-06
### Fix
- Fix identation in blackbox_exporter config

## [5.1.1] - 2023-06-01
### Fix
- Fix sed cmd to not duplicate the lines if already there for blackbox_exporter config

## [5.1.0] - 2022-11-08
### Add
- Add env file path variable to specify custom location

## [5.0.0] - 2022-11-07
### Add
- Add possibility to adapt repeating alerts interval with ALERTMANAGER_REPEAT_INTERVAL and fix more standards values for alertmanager triggers after this validation phase 
- Add possibility to adapt Temperature threshold for alarms firing with ALERTMANAGER_TEMPERATURE_THRESHOLD
- Add new flag to programmatically retrieve Prommanager version
- Add first implementation of Ansible playbook to install Prommanager on multiple machines at the same time
- Add meta definition for Ansible Galaxy
- Add basic documentation to start with this Ansible role via Ansible Galaxy

### Changed
- Improve documentation for configuration
- Improve documentation for architecture design
- Improve documentation by adding https://awesome-prometheus-alerts.grep.to/

### Fixed
- Fix shell2http version number retrieved

### Chore
- Rename apps function to services

## [4.1.0] - 2022-04-05
### Added
- Add alerts for following key values: CPU Load (>80%), RAM (>85%), Storage (>80%), node temperature (>70°C when available)
- Add originating server on messages
### Fixed
- Fix sensitivity for HTTP Probe failure


## [4.0.2] - 2022-04-01
### Fixed 
- Fix alerts containing multiple alerts in it

## [4.0.1] - 2022-04-01
### Added
- Add latest release as preferred download channel (stability)
- Add possibility to override ports used for each service via .env file

### Changed
- Improve .env.example
- Make usage help context more compact 

### Fixed 
- Fix message if shell2http is not installed
- Fix missing jq on certain installation

## [4.0.0] - 2022-04-01
### Added
- Since v4+ this changelog will be based on [Keep a Changelog](https://keepachangelog.com/en/)
- Since v4+ add script as released asset for retro compatibility issues
- Add communication services based on PingMe CLI (https://github.com/kha7iq/pingme)
- Supported bridges are Microsoft Teams, Telegram, Slack, etc. see PingMe for full list

### Changed
- Rename project to be more compliant with Linux Trademark usage
- Retrieve .env values via shdotenv library for more robustness (https://github.com/ko1nksm/shdotenv) 

### Removed
- [WARNING] Breaking change: prometheus full flag use complete word for clarity (seems to be the last breaking change for existing flags)

## [3.0.0] - 2022-03-15
### Added
- Add blackbox_exporter
- Set ipv4 as preferred protocol for blackbox_exporter
- Add sample list of URL to be watched
- Add Alertmanager
- Add an update config option to edit sensitive data in an .env file

### Changed
- Update corresponding command on README.md
- Split config and init for further developments

### Fixed
- Ensure version numbers are present on fresh install

### Removed
- [WARNING] Breaking changes: arguments for install, exec, kill, status switched to lowercase for single letter

## [2.0.0] - 2022-03-14
### Added
- Add an adaptative verbose mode (-vv for WARN, -vvv for INFO, -vvvv for DEBUG)
- Check for argument when mandatory
- Make get and display versions working with apps flags
- Add possibility to start/stop apps separately
- Add possibility to remove apps independently of each other

### Changed
- Improve versions retrieving
- Retrieve status for each app independently via parameter

### Removed
- [WARNING] Breaking change: Split display and retrieve options for services versions

## [1.0.0] - 2022-03-14
### Added
- Add sudo rights control at launch
- Overwrite version to be installed if tag curl OK
- [INFO] Introduction of first [SemVer](https://semver.org/) version

### Changed
- Rewrite option argument parsing
- Use lsof in favour of netstat for listening open ports

### Removed
- [WARNING] Breaking changes for script arguments

[Unreleased]: https://github.com/matbgn/prommanager/compare/v5.1.2...HEAD
[5.1.2]: https://github.com/matbgn/prommanager/compare/v5.1.1...v5.1.2
[5.1.1]: https://github.com/matbgn/prommanager/compare/v5.1.0...v5.1.1
[5.1.0]: https://github.com/matbgn/prommanager/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/matbgn/prommanager/compare/v4.1.0...v5.0.0
[4.1.0]: https://github.com/matbgn/prommanager/compare/v4.0.2...v4.1.0
[4.0.2]: https://github.com/matbgn/prommanager/compare/v4.0.1...v4.0.2
[4.0.1]: https://github.com/matbgn/prommanager/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/matbgn/prommanager/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/matbgn/prommanager/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/matbgn/prommanager/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/matbgn/prommanager/releases/tag/v1.0.0

    GH CLI: gh release create vX.0.0 -t "vX.0.0" -n "See [CHANGELOG.md](CHANGELOG.md) for details" prommanager

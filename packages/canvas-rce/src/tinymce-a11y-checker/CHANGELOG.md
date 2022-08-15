# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.1.1] - 2022-08-10
### Changed
- Updated dependency versions

## [4.1.0] - 2022-08-09
### Added
- A new configurable rule that informs users to not use H1 headings

## [4.0.0] - 2022-08-02
### Added
- A changelog to make changes clear

### Changed
- `checkAccessibility` command's paramater `additional_rules` has been renamed `additionalRules`

### Fixed
- Bug that caused inconsistent checking behavior between `checkAccessibility` and `openAccessibilityChecker` when using a non-default configuration

### Removed
- TinyMCE v4 support

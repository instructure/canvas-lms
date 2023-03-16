# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.1.4] - 2023-02-14

- Fixed a bug where the a11y checker could be opened twice and cause
  content to become deleted
- change `$(npm bin)/command` to `npx command`

## [4.1.3] - 2023-01-30

- Change the violation highlight from an absolutely positioned blue box
  to an outline created with just CSS

## [4.1.2] - 2022-11-30

- Changes to cope with the RCE being put in browser-native fullscreen
- Fixed a bug that over aggressively kept track of the blue box that shows
  the element in violation.

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

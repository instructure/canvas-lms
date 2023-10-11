# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.8.0 - 2023-10-11

### Changed
- Upgraded Instructure UI dependencies to version 8

### Fixed
- A small bug that incorrectly determined media types

## 1.7.1 - 2023-09-26

### Fixed
- An issue where media controls don't respond in Safari
- Accessibility issues when adding media captions
- An issue where inherited media captions don't appear in the media captions list

## 1.7.0 - 2023-08-15

### Added
- Explanations for inherited media captions and associated translations

### Changed
- Reduced amount of console errors when running jest tests by providing missing props, fixing async issues, etc in tests

## 1.6.0 - 2023-06-30

### Added
- An alert if the user uploads a caption file that's too large

### Changed
- Improved the i18n string extraction process

### Fixed
- Some missing translations
- An issue where closed caption selection didn't work in full screen

## 1.4.0 - 2022-11-03

### Changed
- No longer need to provide closed caption language list

## 1.3.0 - 2022-08-17

### Added
- A changelog to make changes clear

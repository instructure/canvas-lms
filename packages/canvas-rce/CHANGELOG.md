# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

# 5.6.12 - 2023-01-26

### Changed

- Update the CHANGELOG for changes that were published with v5.6.11

# 5.6.11 - 2023-01-25

### Changed

- Removed Unsplash support
- Fixed various bugs with fullscreen RCE
- Enhance copy/paste and drag-and-drop into the RCE
- Transform initial content to ensure Canvas URLs are relative and remove unnecessary data attributes

# 5.6.10 - 2022-12-09

### Changed

- Fixed inline preview in non-Canvas settings
- Fixed video embeds in non-Canvas settings
- Fixed fullscreen behavior in non-Canvas settings

### Added

- Properties to disable specific plugins (e.g. word count)

# 5.6.9 - 2022-11-19

### Changed

- Fixed a bug causing errors when used outside of Canvas

# 5.6.8 - 2022-11-16

### Added

- User content enhancement option for opening Canvas links in a new tab

### Changed

- Fixed word count to no longer include contents of @mentions dropdown
- Word count modal can be opened from the status bar
- Fixed a bug related to uploading files in external apps

# 5.6.3 - 2022-11-11

### Changed

- Fixes to handling of relative URLs in enhance user content
- Fixes to document preview in iframe-embedded scenarios

# 5.6.2 - 2022-11-03

### Added

- User content enhancement function for rendering RCE-authored content

### Changed

- RCE now embeds relative links, and uses provided `canvasOrigin` to resolve them
- No longer need to provide the list of closed-caption languages
- Unsplash now respects plugin settings
- Misc bug fixes and enhancements

# 5.6.1 - 2022-09-14

### Added

- Icon Maker features
  - Cropper dragging support
  - Reset button for restoring initial values
  - Restriction on raster image size

### Changed

- Stop throwing error when `timezone` or `features` props aren't provided

## 5.6 - 2022-08-17

### Added

- MacOS keyboard shortcut help
- TypeScript support
- Accessibility Checker rule to require `<h2>` as the highest heading

### Changed

- Fixed dependency cycle between `@instructure/canvas-rce` and
  `@instructure/canvas-media` that caused build errors for external consumers

## 5.5 - 2022-08-04

### Added

- A changelog to make changes clear

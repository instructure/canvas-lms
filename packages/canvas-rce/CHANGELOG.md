# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

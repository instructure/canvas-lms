# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 5.12.2 - 2024-01-31

### Changed

- Moved RCE's makeAllExternalLinksExternalLinks
- Removed doc-previews package
- Removed CommonJS build of RCE

## 5.12.1 - 2024-01-26

### Fixed

- An issue where we were adding file verifiers unnecessarily to non-user files
  which were allowing students access to course files they should not have
  access to
- An issue where type query parameter was duplicated.
- Fix focus ring in RCE content
- Stop adding wrap params to course links

### Changed

- Bump redux-thunk to 3.1.0
- Show full name in hover in All Files tray
- Remove "scroll-into-view"
- jQuery changes
- Upgrade moment to 0.5.43
- Upgrade babel-loader to 9.1.3
- Remove use of InferType
- Show media captions in New Quizzes
- Bump Instui to 8.49


## 5.11.1 - 2023-10-12

### Fixed

- An issue where the RCE can't be built due to an extraneous dependency

## 5.11.0 - 2023-10-10

### Fixed

- Fix styling on a11y checker why IconButton
- fix instui8 regression in course link tray (RCE)
- focus close button on ECL tray launch
- fix video media comment in speedgrader

### Changed

- Bump instui to 8.45.0
- update dockerfiles for node 18
- InstUI 8 upgrade post-work: theme -> themeOverride
- Allow other users to view media in discussions
- Revert "Stop rendering title and CC panels on media tray for locked attachments"

### Added

- respond to all postMessages in active RCE

## 5.10.0 - 2023-09-26

### Fixed

- An issue where media controls don't respond in Safari
- An issue where embedded Studio videos cause unresponsiveness
- A potential race condition in postMessage forwarding

### Changed

- Ignore a11y check on elements with a background image or gradient
- Remove math processing percentage indicator

## 5.9.0 - 2023-08-30

### Fixed

- An issue where LTI postMessages were not working inside active RCE

### Changed

- Encrypt auto-saved RCE content
- Remove dependency on `@instructure/filter-console-messages`

## 5.8.0 - 2023-08-15

### Fixed

- An issue where filenames are incorrectly recognized in the accessibility checker
- An issue where the accessibility checker's color picker would not work with invalid RGBA values
- An issue where the RCS is required to use the new external tools plugin

### Changed

- Removed CJS build from package
- Renamed .js files to .jsx
- Upgraded react-aria-live dependency to v2.0.5
- Removed h1 option from the Headings menu dropdown
- Only typeset math in user content
- Reduced amount of console errors when running jest tests by providing missing props, fixing async issues, etc in tests

### Added

- New translations
- Improved messaging in the Add Course Link tray when there's no results
- Explanations for inherited media captions

## 5.7.0 - 2023-07-18

### Fixed

- Some broken translations in the 'Edit Course Link' tray and the word count modal
- Some Typescript errors
- An issue where the a11y checker incorrectly shows the issues icon

### Changed

- Removed the `rce_new_external_tool_dialog_in_canvas` feature flag
- Removed the deprecated `instructure_external_tools` package code which was not in use
- Replaced themeable with emotion

### Added

- Selected link indicator alert for screenreaders in the 'Edit Course Link' tray

## 5.6.17 - 2023-06-27

### Fixed

- Added some missing media translations
- Fixed some a11y/usability issues in the 'Edit Course Link' tray
- Fixed an icon maker bug related to image compression
- Fixed some issues related to pasting images in Firefox and embedding media

### Changed

- Removed the `rce_improved_placeholders`, `rce_better_paste`, `rce_show_studio_media_options`, and
  `buttons_and_icons_cropper` feature flags
- Improved the accessibility checker's performance

## 5.6.16 - 2023-05-17

### Fixed

- Fullscreen issues with several select components
- A significant number of missing translations across various locales

### Changed

- Restored previous mathjax delimiter config
- Absorbed the `tinymce-a11y-checker` plugin
- Updated the placeholders when inserting media, images, files, etc.
- Adjusted toolbar overflow to slide rather than float
- Moved MathML to one shared location

### Added

- Studio Media Options plugin
- Equilibrium button to the Equation Editor
- Icon support for iWork files

## 5.6.15 - 2023-03-10

### Changed

- Fixed copy/paste from Microsoft Word into the RCE
- Support enhanced copy/paste in a User (vs Course or Group) context
- Fix double-pasting of plain text
- Fix access permissions for links to course files in the RCE, primarily in support of inline preview within new quizzes
- When the canvas JWT expires the RCE calls Canvas to refresh it. The refreshed JWT is now saved so we don't re-refrseh with every api request.
- Updated keyboard shortcuts dialog and removed the Alt-0 shortcut that opens it
- Limit mathjax delimiters to `\(...\)` and `$$...$$`

### Added

- Moved code supporting LTI tools embedded in the RCE from Canvas to the canvas-rce repo

## 5.6.14 - 2023-02-03

### Changed

- Transpile the `??` null-coallescing operator for consumers that don't support it
- Fix focus management when closing keyboard shortcut modal
- Add additional translated strings

## 5.6.13 - 2023-01-30

### Changed

- Update the tinymce-a11y-checker dependency version to 4.1.3 (updated highlight on violations)
- Fixed encoding bug related to quotations
- Altered keyboard shortcuts
- Updated keyboard shortcut modal appearance

## 5.6.12 - 2023-01-26

### Changed

- Update the CHANGELOG for changes that were published with v5.6.11

## 5.6.11 - 2023-01-25

### Changed

- Removed Unsplash support
- Fixed various bugs with fullscreen RCE
- Enhance copy/paste and drag-and-drop into the RCE
- Transform initial content to ensure Canvas URLs are relative and remove unnecessary data attributes

## 5.6.10 - 2022-12-09

### Changed

- Fixed inline preview in non-Canvas settings
- Fixed video embeds in non-Canvas settings
- Fixed fullscreen behavior in non-Canvas settings

### Added

- Properties to disable specific plugins (e.g. word count)

## 5.6.9 - 2022-11-19

### Changed

- Fixed a bug causing errors when used outside of Canvas

## 5.6.8 - 2022-11-16

### Added

- User content enhancement option for opening Canvas links in a new tab

### Changed

- Fixed word count to no longer include contents of @mentions dropdown
- Word count modal can be opened from the status bar
- Fixed a bug related to uploading files in external apps

## 5.6.3 - 2022-11-11

### Changed

- Fixes to handling of relative URLs in enhance user content
- Fixes to document preview in iframe-embedded scenarios

## 5.6.2 - 2022-11-03

### Added

- User content enhancement function for rendering RCE-authored content

### Changed

- RCE now embeds relative links, and uses provided `canvasOrigin` to resolve them
- No longer need to provide the list of closed-caption languages
- Unsplash now respects plugin settings
- Misc bug fixes and enhancements

## 5.6.1 - 2022-09-14

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

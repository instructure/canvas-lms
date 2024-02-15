/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable no-undef */

// this is the first module loaded by webpack (in the vendor bundle). It tells it
// to load chunks from the CDN url configured in config/canvas_cdn.yml

// to make better sense of this:
//
// - __webpack_public_path__ is a magic variable[1] by webpack and only
//   available to modules bundled by webpack
//
// - CANVAS_WEBPACK_PUBLIC_PATH is injected by Webpack through a DefinePlugin[2]
//   whose value is known at compile-time (see webpack config)
//
// [1]: https://webpack.js.org/guides/public-path/#on-the-fly
// [2]: https://webpack.js.org/plugins/define-plugin/
// Also see https://www.rspack.dev/api/modules.html#__webpack_public_path__-webpack-specific
if (typeof __webpack_public_path__ !== 'undefined') {
  __webpack_public_path__ =
    ((window.ENV && window.ENV.ASSET_HOST) || '') + CANVAS_WEBPACK_PUBLIC_PATH
}

/* eslint-enable no-undef */

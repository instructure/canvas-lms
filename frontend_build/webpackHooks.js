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

const exec = require('child_process').exec

module.exports = class WebpackHooks {
  apply(compiler) {
    const isEnabled = JSON.parse(process.env.ENABLE_CANVAS_WEBPACK_HOOKS || 'false')
    if (isEnabled) {
      const {
        CANVAS_WEBPACK_START_HOOK,
        CANVAS_WEBPACK_FAILED_HOOK,
        CANVAS_WEBPACK_DONE_HOOK
      } = process.env

      if (CANVAS_WEBPACK_START_HOOK) {
        compiler.plugin('compile', () => exec(CANVAS_WEBPACK_START_HOOK))
      }

      if (CANVAS_WEBPACK_FAILED_HOOK) {
        compiler.plugin('failed', () => exec(CANVAS_WEBPACK_FAILED_HOOK))
      }

      if (CANVAS_WEBPACK_DONE_HOOK) {
        compiler.plugin('done', () => exec(CANVAS_WEBPACK_DONE_HOOK))
      }
    }
  }
}

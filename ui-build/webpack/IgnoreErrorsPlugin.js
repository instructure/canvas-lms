/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
class IgnoreErrorsPlugin {
  constructor({ errors, warnOnUnencounteredErrors = false }) {
    this.errors = errors
    this.warnOnUnencounteredErrors = warnOnUnencounteredErrors
  }

  apply(compiler) {
    compiler.hooks.compilation.tap('IgnoreErrors', compilation => {
      compilation.hooks.finishModules.tap('IgnoreErrors', modules => {
        for (const selector of this.errors) {
          const error = compilation.errors.find(x => match(selector, x))

          if (error) {
            compilation.errors.splice(compilation.errors.indexOf(error), 1)
          }
          else if (this.warnOnUnencounteredErrors) {
            compilation.warnings.push(
              `[IgnoreErrorsPlugin]\n` +
              `error was never generated and should probably be unlisted:\n` +
              `${JSON.stringify(selector, null, 4)}`
            )
          }
        }

        return modules
      })
    })
  }
}

const match = (a, b) => Object.keys(a).every(prop => a[prop] === b[prop])

module.exports = IgnoreErrorsPlugin
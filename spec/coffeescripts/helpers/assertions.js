/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

const _ = require('underscore')
const axe = require('axe-core')

module.exports = {
  isVisible($el, message = '') {
    ok($el.length, 'elements found')
    ok($el.is(':visible'), `${$el} is visible ${message}`)
  },

  isHidden($el, message) {
    ok($el.length, 'elements found')
    ok(!$el.is(':visible'), `${$el} is hidden ${message}`)
  },

  hasClass($el, className, message) {
    ok($el.length, 'elements found')
    ok($el.hasClass(className), `${$el} has class ${className} ${message}`)
  },

  isAccessible($el, done, options = {}) {
    if (options.a11yReport) {
      if (process.env.A11Y_REPORT) {
        options.ignores = ':html-has-lang, :document-title, :region, :meta-viewport, :skip-link'
      } else {
        ok(true)
        return done()
      }
    }

    const el = $el[0]

    const axeConfig = {
      runOnly: {
        type: 'tag',
        values: ['wcag2a', 'wcag2aa', 'section508', 'best-practice']
      }
    }

    return axe.a11yCheck(el, axeConfig, function(result) {
      const ignores = options.ignores || []
      const violations = _.reject(
        result.violations,
        violation => ignores.indexOf(violation.id) >= 0
      )

      const err = violations.map(violation =>
        [`[${violation.id}] ${violation.help}`, `${violation.helpUrl}\n`].join('\n')
      )

      ok(violations.length === 0, err)

      done()
    })
  },

  contains(string, substring) {
    return QUnit.assert.push(
      string.indexOf(substring) > -1,
      string,
      substring,
      'expected string not found in actual'
    )
  }
}

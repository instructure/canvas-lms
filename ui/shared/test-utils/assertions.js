/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {expect} from '@jest/globals'
import {reject} from 'es-toolkit/compat'
import axe from 'axe-core'

export function isVisible($el) {
  expect($el.length).toBeGreaterThan(0)
  expect($el.is(':visible')).toBeTruthy()
}

export function isHidden($el) {
  expect($el.length).toBeGreaterThan(0)
  expect(!$el.is(':visible')).toBeTruthy()
}

export function hasClass($el, className) {
  expect($el.length).toBeGreaterThan(0)
  expect($el.hasClass(className)).toBeTruthy()
}

export function isAccessible($el, options = {}) {
  // Handle legacy signature where second arg might be a done callback (deprecated)
  if (typeof options === 'function') {
    // Legacy done callback - ignore it since Vitest deprecated done()
    options = arguments[2] || {}
  }

  if (options.a11yReport) {
    if (process.env.A11Y_REPORT) {
      options.ignores = ':html-has-lang, :document-title, :region, :meta-viewport, :skip-link'
    } else {
      expect(true).toBe(true)
      return Promise.resolve()
    }
  }

  // Validate element exists before accessing
  if (!$el) {
    return Promise.reject(new Error('Invalid element passed to axe.run'))
  }

  const el = $el instanceof Element ? $el : $el[0]

  const axeConfig = {
    runOnly: {
      type: 'tag',
      values: ['wcag2a', 'wcag2aa', 'section508', 'best-practice'],
    },
  }

  return new Promise((resolve, _reject) => {
    axe.a11yCheck(el, axeConfig, result => {
      const ignores = options.ignores || []
      const violations = reject(result.violations, violation => ignores.indexOf(violation.id) >= 0)

      const err = violations.map(violation =>
        [`[${violation.id}] ${violation.help}`, `${violation.helpUrl}\n`].join('\n'),
      )

      if (violations.length) {
        console.error(err)
      }

      try {
        expect(violations).toHaveLength(0)
        resolve()
      } catch (error) {
        _reject(error)
      }
    })
  })
}

export function contains(string, substring) {
  expect(string).toContain(substring)
}

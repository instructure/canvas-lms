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

import {reject} from 'lodash'
import axe from 'axe-core'

const isAccessible = async (element, options = {}) => {
  if (options.a11yReport) {
    if (process.env.A11Y_REPORT) {
      options.ignores = ':html-has-lang, :document-title, :region, :meta-viewport, :skip-link'
    } else {
      expect(true).toBe(true)
      return
    }
  }

  // check if the element is a valid DOM element
  if (!(element instanceof HTMLElement)) {
    throw new Error('Invalid element passed to axe.run')
  }

  // attach element to the DOM if it’s not already part of it
  if (!document.body.contains(element)) {
    document.body.appendChild(element)
  }

  const axeConfig = {
    runOnly: {
      type: 'tag',
      values: ['wcag2a', 'wcag2aa', 'section508', 'best-practice'],
    },
  }

  const result = await axe.run(element, axeConfig)
  const ignores = options.ignores || []
  const violations = reject(result.violations, violation => ignores.includes(violation.id))

  // if there are violations, fail the test and log the errors
  expect(violations).toHaveLength(0)

  if (violations.length > 0) {
    const err = violations
      .map(violation =>
        [`[${violation.id}] ${violation.help}`, `${violation.helpUrl}\n`].join('\n'),
      )
      .join('\n')

     
    console.error('Accessibility violations:', err)
  }

  // clean up the element from the DOM if it was added
  if (document.body.contains(element)) {
    document.body.removeChild(element)
  }
}

export {isAccessible}

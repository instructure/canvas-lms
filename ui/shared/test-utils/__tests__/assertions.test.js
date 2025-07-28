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

import {isAccessible} from '../assertions'

describe('assertions', () => {
  describe('isAccessible', () => {
    let element

    beforeEach(() => {
      element = document.createElement('div')
    })

    afterEach(() => {
      if (document.body.contains(element)) {
        document.body.removeChild(element)
      }
    })

    it('passes for accessible elements', async () => {
      element.innerHTML = '<button>Click me</button>'
      await isAccessible(element)
    })

    it('handles a11y report option', async () => {
      const oldEnv = process.env.A11Y_REPORT
      process.env.A11Y_REPORT = true

      try {
        await isAccessible(element, {a11yReport: true})
        expect(true).toBe(true) // Should reach here without error
      } finally {
        process.env.A11Y_REPORT = oldEnv
      }
    })

    it('handles ignores option', async () => {
      // Create an element that would normally fail WCAG but we ignore that rule
      element.innerHTML = '<img src="test.jpg">' // Missing alt attribute
      await isAccessible(element, {ignores: ['image-alt']})
    })

    it('throws error for invalid element', async () => {
      await expect(isAccessible(null)).rejects.toThrow('Invalid element passed to axe.run')
    })

    it('cleans up elements added to DOM', async () => {
      const detachedElement = document.createElement('div')
      await isAccessible(detachedElement)
      expect(document.body.contains(detachedElement)).toBe(false)
    })

    it('fails for inaccessible elements', async () => {
      element.innerHTML = '<img src="test.jpg">' // Missing alt attribute
      await expect(isAccessible(element)).rejects.toThrow()
    })
  })
})

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

import {createErrorMessage, handleRegistrationRedirect} from '../helpers'

describe('Helpers', () => {
  describe('createErrorMessage', () => {
    it('should return a FormMessage array with an error when text is provided', () => {
      const result = createErrorMessage('This is an error')
      expect(result).toEqual([{type: 'error', text: 'This is an error'}])
    })

    it('should return an empty array when no text is provided', () => {
      const result = createErrorMessage('')
      expect(result).toEqual([])
    })
  })

  describe('handleRegistrationRedirect', () => {
    let originalLocation: Location

    beforeAll(() => {
      originalLocation = window.location
      Object.defineProperty(window, 'location', {
        configurable: true,
        value: {
          replace: jest.fn(),
        },
      })
    })

    afterAll(() => {
      Object.defineProperty(window, 'location', {
        configurable: true,
        value: originalLocation,
      })
    })

    it('should redirect to destination if destination is provided', () => {
      handleRegistrationRedirect({destination: '/dashboard'})
      expect(window.location.replace).toHaveBeenCalledWith('/dashboard')
    })

    it('should redirect to course URL if course data is provided', () => {
      handleRegistrationRedirect({
        course: {
          course: {
            id: 123,
          },
        },
      })
      expect(window.location.replace).toHaveBeenCalledWith('/courses/123?registration_success=1')
    })

    it('should redirect to default URL if no destination or course is provided', () => {
      handleRegistrationRedirect({})
      expect(window.location.replace).toHaveBeenCalledWith('/?registration_success=1')
    })
  })
})

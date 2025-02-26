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

import {assignLocation} from '@canvas/util/globalUtils'
import {createErrorMessage, handleRegistrationRedirect} from '../helpers'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('Helpers', () => {
  describe('createErrorMessage', () => {
    it('should return a FormMessage array with an error when text is provided', () => {
      const result = createErrorMessage('This is an error')
      expect(result).toEqual([{type: 'newError', text: 'This is an error'}])
    })

    it('should return an empty array when no text is provided', () => {
      const result = createErrorMessage('')
      expect(result).toEqual([])
    })
  })

  describe('handleRegistrationRedirect', () => {
    it('should redirect to destination if destination is provided', () => {
      handleRegistrationRedirect({destination: '/dashboard'})
      expect(assignLocation).toHaveBeenCalledWith('/dashboard')
    })

    it('should redirect to course URL if course data is provided', () => {
      handleRegistrationRedirect({
        course: {
          course: {
            id: 123,
          },
        },
      })
      expect(assignLocation).toHaveBeenCalledWith('/courses/123?registration_success=1')
    })

    it('should redirect to default URL if no destination or course is provided', () => {
      handleRegistrationRedirect({})
      expect(assignLocation).toHaveBeenCalledWith('/?registration_success=1')
    })
  })
})

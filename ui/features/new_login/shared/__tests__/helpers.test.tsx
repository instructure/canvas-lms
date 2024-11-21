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

import type {PasswordPolicy} from '../../types'
import {createErrorMessage, handleRegistrationRedirect, validatePassword} from '../helpers'

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

  describe('validatePassword', () => {
    const policy: PasswordPolicy = {
      minimumCharacterLength: 8,
      requireNumberCharacters: true,
      requireSymbolCharacters: true,
    }

    it('should return null when password meets all policy requirements', () => {
      const password = 'Valid123!'
      const result = validatePassword(password, policy)
      expect(result).toBeNull()
    })

    it('should return an error when password is too short', () => {
      const password = 'Short1!'
      const result = validatePassword(password, policy)
      expect(result).toBe('Password must be at least 8 characters long.')
    })

    it('should return an error when password does not include a numeric character', () => {
      const password = 'NoNumber!'
      const result = validatePassword(password, policy)
      expect(result).toBe('Password must include at least one numeric character.')
    })

    it('should return an error when password does not include a special character', () => {
      const password = 'NoSpecial123'
      const result = validatePassword(password, policy)
      expect(result).toBe('Password must include at least one special character.')
    })

    it('should return null when the password meets the length requirement only', () => {
      const updatedPolicy = {
        ...policy,
        requireNumberCharacters: false,
        requireSymbolCharacters: false,
      }
      const password = 'OnlyLength'
      const result = validatePassword(password, updatedPolicy)
      expect(result).toBeNull()
    })

    it('should validate correctly if requireNumberCharacters is false', () => {
      const updatedPolicy = {
        ...policy,
        requireNumberCharacters: false,
      }
      const password = 'NoNumber!'
      const result = validatePassword(password, updatedPolicy)
      expect(result).toBeNull()
    })

    it('should validate correctly if requireSymbolCharacters is false', () => {
      const updatedPolicy = {
        ...policy,
        requireSymbolCharacters: false,
      }
      const password = 'NoSymbol123'
      const result = validatePassword(password, updatedPolicy)
      expect(result).toBeNull()
    })

    it('should handle undefined password gracefully', () => {
      const result = validatePassword(undefined as unknown as string, policy)
      expect(result).toBeNull()
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

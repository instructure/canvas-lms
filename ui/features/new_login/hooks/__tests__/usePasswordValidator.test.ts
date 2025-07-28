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

import {renderHook} from '@testing-library/react-hooks'
import {usePasswordValidator} from '..'
import type {PasswordPolicy} from '../../types'

describe('usePasswordValidator', () => {
  const policy: PasswordPolicy = {
    minimumCharacterLength: 8,
    requireNumberCharacters: true,
    requireSymbolCharacters: true,
  }

  it('should return null when password meets all policy requirements', () => {
    const {result} = renderHook(() => usePasswordValidator(policy))
    const validatePassword = result.current
    const password = 'Valid123!'
    const validationError = validatePassword(password)
    expect(validationError).toBeNull()
  })

  it('should return an error when password is too short', () => {
    const {result} = renderHook(() => usePasswordValidator(policy))
    const validatePassword = result.current
    const password = 'Short1!'
    const validationError = validatePassword(password)
    expect(validationError).toBe('too_short')
  })

  it('should return an error when password does not include a numeric character', () => {
    const {result} = renderHook(() => usePasswordValidator(policy))
    const validatePassword = result.current
    const password = 'NoNumber!'
    const validationError = validatePassword(password)
    expect(validationError).toBe('no_digits')
  })

  it('should return an error when password does not include a special character', () => {
    const {result} = renderHook(() => usePasswordValidator(policy))
    const validatePassword = result.current
    const password = 'NoSpecial123'
    const validationError = validatePassword(password)
    expect(validationError).toBe('no_symbols')
  })

  it('should return null when the password meets the length requirement only', () => {
    const updatedPolicy: PasswordPolicy = {
      ...policy,
      requireNumberCharacters: false,
      requireSymbolCharacters: false,
    }
    const {result} = renderHook(() => usePasswordValidator(updatedPolicy))
    const validatePassword = result.current
    const password = 'OnlyLength'
    const validationError = validatePassword(password)
    expect(validationError).toBeNull()
  })

  it('should validate correctly if requireNumberCharacters is false', () => {
    const updatedPolicy: PasswordPolicy = {
      ...policy,
      requireNumberCharacters: false,
    }
    const {result} = renderHook(() => usePasswordValidator(updatedPolicy))
    const validatePassword = result.current
    const password = 'NoNumber!'
    const validationError = validatePassword(password)
    expect(validationError).toBeNull()
  })

  it('should validate correctly if requireSymbolCharacters is false', () => {
    const updatedPolicy: PasswordPolicy = {
      ...policy,
      requireSymbolCharacters: false,
    }
    const {result} = renderHook(() => usePasswordValidator(updatedPolicy))
    const validatePassword = result.current
    const password = 'NoSymbol123'
    const validationError = validatePassword(password)
    expect(validationError).toBeNull()
  })

  it('should handle undefined password gracefully', () => {
    const {result} = renderHook(() => usePasswordValidator(policy))
    const validatePassword = result.current
    const validationError = validatePassword(undefined as unknown as string)
    expect(validationError).toBe('too_short')
  })

  it('should return null if no password policy is provided', () => {
    const {result} = renderHook(() => usePasswordValidator())
    const validatePassword = result.current
    const password = 'AnyPassword123!'
    const validationError = validatePassword(password)
    expect(validationError).toBeNull()
  })
})

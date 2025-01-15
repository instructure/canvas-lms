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
import {useServerErrorsMap} from '../useServerErrorsMap'

describe('useServerErrorsMap', () => {
  it('returns default error messages without a password policy', () => {
    const {result} = renderHook(() => useServerErrorsMap())

    expect(result.current['user.name.blank']).toBe('Please enter your name.')
    expect(result.current['pseudonym.password.too_short']).toBe(
      'Password does not meet the length requirement.'
    )
    expect(result.current['pseudonym.password.too_long']).toBe(
      'Password exceeds the allowed length.'
    )
  })

  it('returns error messages with specific password policy values', () => {
    const passwordPolicy = {
      minimumCharacterLength: 8,
      maximumCharacterLength: 50,
      maxRepeats: 3,
      maxSequence: 4,
    }
    const {result} = renderHook(() => useServerErrorsMap(passwordPolicy))

    expect(result.current['pseudonym.password.too_short']).toBe(
      'Password must be at least 8 characters.'
    )
    expect(result.current['pseudonym.password.too_long']).toBe(
      'Password cannot exceed 50 characters.'
    )
    expect(result.current['pseudonym.password.repeated']).toBe(
      'Password cannot have the same character more than 3 times in a row.'
    )
    expect(result.current['pseudonym.password.sequence']).toBe(
      'Password cannot include a sequence of 4 or more characters (e.g., “abcdef”).'
    )
  })

  it('handles missing or undefined password policy gracefully', () => {
    const {result} = renderHook(() => useServerErrorsMap(undefined))

    expect(result.current['pseudonym.password.too_short']).toBe(
      'Password does not meet the length requirement.'
    )
    expect(result.current['pseudonym.password.too_long']).toBe(
      'Password exceeds the allowed length.'
    )
  })

  it('returns all error keys with expected messages', () => {
    const {result} = renderHook(() => useServerErrorsMap())

    expect(result.current['user.name.blank']).toBe('Please enter your name.')
    expect(result.current['user.self_enrollment_code.blank']).toBe(
      'Please enter an enrollment code.'
    )
    expect(result.current['user.terms_of_use.accepted']).toBe(
      'You must accept the terms to proceed.'
    )
    expect(result.current['pseudonym.unique_id.too_long']).toBe(
      'Username must be 100 characters or fewer.'
    )
    expect(result.current['pairing_code.code.invalid']).toBe('The pairing code is invalid.')
  })
})

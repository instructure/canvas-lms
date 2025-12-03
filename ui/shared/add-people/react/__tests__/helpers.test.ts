/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {validateEmailForNewUser, parseNameList, findEmailInEntry} from '../helpers'
import fc from 'fast-check'

describe('validateEmailForNewUser', () => {
  it('returns null for valid email', () => {
    fc.assert(
      fc.property(fc.emailAddress(), email => {
        const result = validateEmailForNewUser({email})
        expect(result).toBeNull()
      }),
    )
  })

  it('returns error message for invalid email', () => {
    const result = validateEmailForNewUser({email: 'invalid-email'})
    expect(result).toBe('Invalid email address.')
  })

  it('returns error message for empty email', () => {
    const result = validateEmailForNewUser({email: ''})
    expect(result).toBe('Email is required.')
  })

  it('returns null for email with apostrophes', () => {
    const result = validateEmailForNewUser({email: "some.user+test'user@instructure.com"})
    expect(result).toBeNull()
  })
})

describe('parseNameList', () => {
  it('handles empty input', () => {
    const result = parseNameList('')
    expect(result).toEqual([])
  })

  it('splits on commas and newlines', () => {
    const input = 'Alice,Bob\nCharlie,David\nEve'
    const result = parseNameList(input)
    expect(result).toEqual(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])
  })

  it('handles quoted commas correctly', () => {
    const input = '"Doe, John",Jane Smith\n"Brown, Bob"'
    const result = parseNameList(input)
    expect(result).toEqual(['"Doe, John"', 'Jane Smith', '"Brown, Bob"'])
  })

  it('returns array of trimmed non-empty strings', () => {
    fc.assert(
      fc.property(fc.string({minLength: 1}), input => {
        const result = parseNameList(input)
        expect(result).toBeInstanceOf(Array)
        for (const item of result) {
          expect(typeof item).toBe('string')
          expect(item.length).toBeGreaterThan(0)
          expect(item).toBe(item.trim())
        }
      }),
    )
  })
})

describe('findEmailInEntry', () => {
  it('extracts standalone email address', () => {
    expect(findEmailInEntry('john@example.com')).toBe('john@example.com')
  })

  it('extracts email from name and email format', () => {
    expect(findEmailInEntry('John Doe john@example.com')).toBe('john@example.com')
  })

  it('returns undefined when no email found', () => {
    expect(findEmailInEntry('John Doe')).toBeUndefined()
  })

  it('returns first email when multiple exist', () => {
    expect(findEmailInEntry('john@example.com jane@example.com')).toBe('john@example.com')
  })

  it('finds and returns email addresses', () => {
    const STRING_WITHOUT_AT_SIGN_REGEX = /^[^@]*$/
    fc.assert(
      fc.property(
        fc.tuple(fc.stringMatching(STRING_WITHOUT_AT_SIGN_REGEX), fc.emailAddress(), fc.string()),
        ([before, email, after]) => {
          const entry = `${before} ${email} ${after}`
          expect(findEmailInEntry(entry)).toBe(email)
        },
      ),
    )
  })
})

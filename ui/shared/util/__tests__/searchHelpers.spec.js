/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Helpers from '../searchHelpers'

describe('searchHelpers#exactMatchRegex', () => {
  let regex

  beforeEach(() => {
    regex = Helpers.exactMatchRegex('hello!')
  })

  test('tests true against an exact match', () => {
    expect(regex.test('hello!')).toBe(true)
  })

  test('ignores case', () => {
    expect(regex.test('Hello!')).toBe(true)
  })

  test('tests false if it is a substring', () => {
    expect(regex.test('hello!sir')).toBe(false)
  })

  test('tests false against a completely different string', () => {
    expect(regex.test('cat')).toBe(false)
  })
})

describe('searchHelpers#startOfStringRegex', () => {
  let regex

  beforeEach(() => {
    regex = Helpers.startOfStringRegex('hello!')
  })

  test('tests true against an exact match', () => {
    expect(regex.test('hello!')).toBe(true)
  })

  test('ignores case', () => {
    expect(regex.test('Hello!')).toBe(true)
  })

  test('tests false if it is a substring that does not start at the beginning of the test string', () => {
    expect(regex.test('bhello!sir')).toBe(false)
  })

  test('tests true if it is a substring that starts at the beginning of the test string', () => {
    expect(regex.test('hello!sir')).toBe(true)
  })

  test('tests false against a completely different string', () => {
    expect(regex.test('cat')).toBe(false)
  })
})

describe('searchHelpers#substringMatchRegex', () => {
  let regex

  beforeEach(() => {
    regex = Helpers.substringMatchRegex('hello!')
  })

  test('tests true against an exact match', () => {
    expect(regex.test('hello!')).toBe(true)
  })

  test('ignores case', () => {
    expect(regex.test('Hello!')).toBe(true)
  })

  test('tests true if it is a substring that does not start at the beginning of the test string', () => {
    expect(regex.test('bhello!sir')).toBe(true)
  })

  test('tests true if it is a substring that starts at the beginning of the test string', () => {
    expect(regex.test('hello!sir')).toBe(true)
  })

  test('tests false against a completely different string', () => {
    expect(regex.test('cat')).toBe(false)
  })
})

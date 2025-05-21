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

import {getConcentratedSegments, splitSearchAndResult} from '../searchHighlighting'

const text = 'its easy to test algorithms by writing good test cases'

describe('searchHighlighting', () => {
  it('should not be split up if text is short', () => {
    const searchExpression = new RegExp(`(algorithms)`, 'gi')
    const words = text.split(' ')
    const result = getConcentratedSegments(searchExpression, words)
    expect(result).toBe(text)
  })

  it('should be surrounded by ellipses when segment is from the middle', () => {
    const searchExpression = new RegExp(`(algorithms)`, 'gi')
    const words = text.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 5,
      maxSegments: 1,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('...to test algorithms by writing...')
  })

  it('should end with ellipses when the segment is from the start', () => {
    const searchExpression = new RegExp(`(easy)`, 'gi')
    const words = text.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 5,
      maxSegments: 1,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('its easy to test algorithms...')
  })

  it('should start with ellipses when the segment is from the end', () => {
    const searchExpression = new RegExp(`(good)`, 'gi')
    const words = text.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 5,
      maxSegments: 1,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('...by writing good test cases')
  })

  it('should not show overlapping segments', () => {
    const overlappingText =
      'Here is a reason to reason through your assignments before submitting on Canvas '
    const searchExpression = new RegExp(`(reason)`, 'gi')
    const words = overlappingText.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 5,
      maxSegments: 2,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('...is a reason to reason...')
  })

  it('should show the first segment if there are no search term matches', () => {
    const searchExpression = new RegExp(`(notfound)`, 'gi')
    const words = text.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 5,
      maxSegments: 1,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('its easy to test algorithms...')
  })

  it('concats multiple segments', () => {
    const searchExpression = new RegExp(`(test)`, 'gi')
    const words = text.split(' ')
    // simulate a long input by overriding the default options
    const result = getConcentratedSegments(searchExpression, words, {
      segmentLength: 3,
      maxSegments: 2,
      granularity: 1,
    })
    // one segment of 5 words
    expect(result).toBe('...to test algorithms...good test cases')
  })

  it('converts search query to RegEx and result into an array of words', () => {
    const searchTerm = 'algorithms'
    const {words, searchExpression} = splitSearchAndResult(text, searchTerm)
    expect(words).toHaveLength(10)
    expect(searchExpression).toBeInstanceOf(RegExp)
    expect(searchExpression).toEqual(new RegExp(`(${searchTerm})`, 'gi'))
  })
})

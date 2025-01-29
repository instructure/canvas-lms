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

import gradebook_uploads from '../index'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

describe('gradebook_uploads#createGeneralFormatter', () => {
  let formatter

  beforeEach(() => {
    formatter = gradebook_uploads.createGeneralFormatter('foo')
  })

  it('returns expected lookup value', () => {
    const formatted = formatter(null, null, {foo: 'bar'})
    expect(formatted).toBe('bar')
  })

  it('returns empty string when lookup value missing', () => {
    const formatted = formatter(null, null, null)
    expect(formatted).toBe('')
  })

  it('escapes passed-in HTML', () => {
    const formatted = formatter(null, null, {foo: 'bar & <baz>'})
    expect(formatted).toBe('bar &amp; &lt;baz&gt;')
  })
})

describe('gradebook_uploads#createNumberFormatter', () => {
  it('returns empty string when value missing', () => {
    const formatter = gradebook_uploads.createNumberFormatter('foo')
    const formatted = formatter(null, null, null)
    expect(formatted).toBe('')
  })

  it('delegates to GradeFormatHelper#formatGrade', () => {
    const formatGradeSpy = jest.spyOn(GradeFormatHelper, 'formatGrade')
    const formatter = gradebook_uploads.createNumberFormatter('foo')
    formatter(null, null, {})
    expect(formatGradeSpy).toHaveBeenCalled()
    formatGradeSpy.mockRestore()
  })
})

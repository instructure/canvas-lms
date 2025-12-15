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
 * with this program. If not, see &lt;http://www.gnu.org/licenses/&gt;.
 */

import $ from 'jquery'
import {isChangeMultiFuncBound} from '../utils/changeMultiFunc'

describe('isChangeMultiFuncBound', () => {
  beforeEach(() => {
    $._data = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('gets events from data on first element', () => {
    const $el = [{}]
    isChangeMultiFuncBound($el)
    expect($._data).toHaveBeenCalledWith($el[0], 'events')
  })

  it('returns true if element has correct change event', () => {
    const $el = [{}]
    const events = {
      change: [{handler: {origFuncNm: 'changeMultiFunc'}}],
    }
    $._data.mockReturnValue(events)
    expect(isChangeMultiFuncBound($el)).toBe(true)
  })

  it('returns false if element has incorrect change event', () => {
    const $el = [{}]
    const events = {
      change: [{handler: {name: 'other'}}],
    }
    $._data.mockReturnValue(events)
    expect(isChangeMultiFuncBound($el)).toBe(false)
  })
})

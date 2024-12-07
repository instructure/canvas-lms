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

import $ from 'jquery'
import 'jqueryui/progressbar'

describe('Progressbar Widget', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append('<div id="progressbar"></div>')
    $('#progressbar').progressbar()
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('initializes with value of 0', () => {
    const $progressbar = $('#progressbar')
    expect($progressbar.progressbar('value')).toBe(0)
  })

  it('updates value correctly', () => {
    const $progressbar = $('#progressbar')
    $progressbar.progressbar('value', 50)
    expect($progressbar.progressbar('value')).toBe(50)
  })

  it('has correct default options', () => {
    const $progressbar = $('#progressbar')
    const options = $progressbar.progressbar('option')
    expect(options.value).toBe(0)
    expect(options.max).toBe(100)
  })
})

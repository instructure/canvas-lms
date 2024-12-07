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
import '../jquery.simulate'
import 'jqueryui/datepicker'

describe('Datepicker Widget', () => {
  beforeEach(() => {
    expect($.fn.datepicker).toBeDefined()
    document.body.innerHTML = '<div id="fixtures"></div>'
    $('#fixtures').append('<input type="text" id="datepicker">')
    $('#datepicker').datepicker({
      showAnim: null, // disable animations for more predictable tests
    })
  })

  afterEach(() => {
    const $datepicker = $('#datepicker')
    if ($datepicker.length) {
      $datepicker.datepicker('destroy')
    }
    document.body.innerHTML = ''
  })

  it('initializes with datepicker class', () => {
    const $datepicker = $('#datepicker')
    expect($datepicker.hasClass('hasDatepicker')).toBe(true)
  })

  it('sets and gets date correctly', () => {
    const $datepicker = $('#datepicker')
    const date = new Date()
    date.setHours(0, 0, 0, 0)

    $datepicker.datepicker('setDate', date)
    const retrievedDate = $datepicker.datepicker('getDate')
    retrievedDate.setHours(0, 0, 0, 0)

    expect(retrievedDate instanceof Date).toBe(true)
    expect(retrievedDate.getTime()).toBe(date.getTime())
  })

  it('has expected default options', () => {
    const $datepicker = $('#datepicker')

    expect($datepicker.datepicker('option', 'showAnim')).toBeNull()
    expect($datepicker.datepicker('option', 'dateFormat')).toBe('mm/dd/yy')
  })

  it('updates input value when date is selected', () => {
    const $datepicker = $('#datepicker')
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    $datepicker.datepicker('setDate', today)
    const value = $datepicker.val()
    const expectedValue = $.datepicker.formatDate('mm/dd/yy', today)

    expect(value).toBe(expectedValue)
  })
})

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

import {recordEulaAgreement, verifyPledgeIsChecked} from '../helper'
import $ from 'jquery'
import 'jquery-migrate'

describe('SubmitAssignmentHelper', () => {
  let alertMock

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    alertMock = jest.spyOn(window, 'alert').mockImplementation(() => {})
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.clearAllMocks()
    jest.useRealTimers()
  })

  describe('recordEulaAgreement', () => {
    it('sets the input value to current time when checked is true', () => {
      const now = new Date('2024-01-01')
      jest.useFakeTimers().setSystemTime(now)

      document.getElementById('fixtures').innerHTML = `
        <input type='checkbox' name='test' class='checkbox-test'>
        <input type='checkbox' name='test two' class='checkbox-test'>
      `

      recordEulaAgreement('.checkbox-test', true)

      const inputs = document.querySelectorAll('.checkbox-test')
      inputs.forEach(input => {
        expect(input.value).toBe(now.getTime().toString())
      })
    })

    it('clears the value when checked is false', () => {
      const now = new Date('2024-01-01')
      jest.useFakeTimers().setSystemTime(now)

      document.getElementById('fixtures').innerHTML = `
        <input type='checkbox' name='test' class='checkbox-test'>
        <input type='checkbox' name='test two' class='checkbox-test'>
      `

      recordEulaAgreement('.checkbox-test', false)

      const inputs = document.querySelectorAll('.checkbox-test')
      inputs.forEach(input => {
        expect(input.value).toBe('')
      })
    })
  })

  describe('verifyPledgeIsChecked', () => {
    it('returns true when checkbox does not exist', () => {
      expect(verifyPledgeIsChecked($('#does_not_exist'))).toBe(true)
    })

    it('returns true when checkbox exists and is checked', () => {
      const checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = true
      checkbox.id = 'test-checkbox'
      document.getElementById('fixtures').appendChild(checkbox)

      expect(verifyPledgeIsChecked($('#test-checkbox'))).toBe(true)
    })

    it('returns false when checkbox exists and is not checked', () => {
      const checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = false
      checkbox.id = 'test-checkbox'
      document.getElementById('fixtures').appendChild(checkbox)

      expect(verifyPledgeIsChecked($('#test-checkbox'))).toBe(false)
    })

    it('alerts the user when checkbox is not checked', () => {
      const errorMessage =
        'You must agree to the submission pledge before you can submit this assignment.'

      const checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = false
      checkbox.id = 'test-checkbox'
      document.getElementById('fixtures').appendChild(checkbox)

      verifyPledgeIsChecked($('#test-checkbox'))

      expect(alertMock).toHaveBeenCalledWith(errorMessage)
    })
  })
})

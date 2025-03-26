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

import {recordEulaAgreement} from '../helper'

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
})

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

import {
  recordEulaAgreement,
  verifyPledgeIsChecked,
} from 'ui/features/submit_assignment/jquery/helper'
import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('SubmitAssignmentHelper', {
  teardown() {
    let ENV
    $('#fixtures').html('')
    ENV = null
  },
})

test('Sets the input value to the current time if checked is true for all eula inputs', () => {
  const now = new Date()
  const clock = sinon.useFakeTimers(now.getTime())
  const inputHtml = `\
<input type='checkbox' name='test' class='checkbox-test'></input>
<input type='checkbox' name='test two' class='checkbox-test'></input>\
`
  $('#fixtures').append(inputHtml)
  recordEulaAgreement('.checkbox-test', true)
  const inputs = document.querySelectorAll('.checkbox-test')
  for (const val of inputs) {
    equal(val.value, now.getTime())
  }
  return clock.restore()
})

test('Clears the value if the input is not checked', () => {
  const now = new Date()
  const clock = sinon.useFakeTimers(now.getTime())
  const inputHtml = `\
<input type='checkbox' name='test' class='checkbox-test'></input>
<input type='checkbox' name='test two' class='checkbox-test'></input>\
`
  $('#fixtures').append(inputHtml)
  recordEulaAgreement('.checkbox-test', false)
  const inputs = document.querySelectorAll('.checkbox-test')
  for (const val of inputs) {
    equal(val.value, '')
  }
  return clock.restore()
})

test('returns true if checkbox does not exist', () => {
  ok(verifyPledgeIsChecked($('#does_not_exist')))
})

test('returns true if the checkbox exists and is checked', () => {
  const checkbox = document.createElement('input')
  checkbox.type = 'checkbox'
  checkbox.checked = true
  checkbox.id = 'test-checkbox'
  document.getElementById('fixtures').appendChild(checkbox)

  ok(verifyPledgeIsChecked($('#test-checkbox')))
})

test('returns false if the checkbox exists and is not checked', () => {
  const checkbox = document.createElement('input')
  checkbox.type = 'checkbox'
  checkbox.checked = false
  checkbox.id = 'test-checkbox'
  document.getElementById('fixtures').appendChild(checkbox)

  notOk(verifyPledgeIsChecked($('#test-checkbox')))
})

test('alerts the user is the checkbox is not checked', () => {
  const errorMessage =
    'You must agree to the submission pledge before you can submit this assignment.'

  const alertSpy = sinon.spy()
  const original_alert = window.alert
  window.alert = alertSpy

  const checkbox = document.createElement('input')
  checkbox.type = 'checkbox'
  checkbox.checked = false
  checkbox.id = 'test-checkbox'
  document.getElementById('fixtures').appendChild(checkbox)

  verifyPledgeIsChecked($('#test-checkbox'))

  ok(alertSpy.calledWith(errorMessage))
  window.alert = original_alert
})

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

import jQuery from 'jquery'
import 'jquery.cookie'
import {submitHtmlForm} from '../submitHtmlForm'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toBe(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let action, method, md5, csrfToken
let appendToSpy, triggerMock

function getForm() {
  submitHtmlForm(action, method, md5)
  // The form is the jQuery object that appendTo was called on
  return appendToSpy.mock.instances[0]
}

describe('submitHtmlForm', () => {
  beforeEach(() => {
    // Reset mocks before each test to ensure clean state
    appendToSpy = jest.spyOn(jQuery.fn, 'appendTo').mockImplementation(function () {
      return this
    })
    jest.spyOn(jQuery.fn, 'submit').mockImplementation(function () {
      return this
    })
    triggerMock = jest.spyOn(jQuery.fn, 'trigger').mockImplementation(function () {
      return this
    })
    action = '/foo'
    method = 'PUT'
    md5 = '0123456789abcdef0123456789abcdef'
    csrfToken = 'csrftoken'
    jest.spyOn(jQuery, 'cookie').mockReturnValue(csrfToken)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('sets action', () => {
    const form = getForm()
    equal(form.attr('action'), action, 'form has the right action')
  })

  test('uses post', () => {
    const form = getForm()
    equal(form.attr('method'), 'POST', 'form method is post')
  })

  test('sets _method', () => {
    const input = getForm().find('input[name=_method]')
    equal(input.val(), method, 'the _method field is set')
  })

  test('sets authenticity_token', () => {
    const input = getForm().find('input[name=authenticity_token]')
    equal(input.val(), csrfToken, 'the csrf token is set')
  })

  test('sets brand config md5 if defined', () => {
    const input = getForm().find('input[name=brand_config_md5]')
    equal(input.val(), md5, 'the md5 is set')
  })

  // passes in QUnit, fails in Jest
  test.skip('does not set brand config md5 if not defined', () => {
    md5 = undefined
    const input = getForm().find('input[name=brand_config_md5]')
    equal(input.size(), 0, 'the md5 is not set')
  })

  test('appends form to body', () => {
    submitHtmlForm(action, method, md5)
    ok(
      appendToSpy.mock.calls.some(call => call[0] === 'body'),
      'appends form to body',
    )
  })

  test('submits the form', () => {
    getForm()
    ok(
      triggerMock.mock.calls.some(call => call[0] === 'submit'),
      'submit event triggered',
    )
  })
})

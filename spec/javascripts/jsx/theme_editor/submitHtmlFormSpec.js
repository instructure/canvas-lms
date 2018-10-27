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

import submitHtmlForm from 'jsx/theme_editor/submitHtmlForm'

let action, method, md5, csrfToken, form

QUnit.module('submitHtmlForm', {
  setup() {
    sandbox.spy(jQuery.fn, 'appendTo')
    sandbox.stub(jQuery.fn, 'submit')
    action = '/foo'
    method = 'PUT'
    md5 = '0123456789abcdef0123456789abcdef'
    csrfToken = 'csrftoken'
    sandbox.stub(jQuery, 'cookie').returns(csrfToken)
  }
})

function getForm() {
  submitHtmlForm(action, method, md5)
  return jQuery.fn.appendTo.firstCall.thisValue
}

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

test('does not set brand config md5 if not defined', () => {
  md5 = undefined
  const input = getForm().find('input[name=brand_config_md5]')
  equal(input.size(), 0, 'the md5 is not set')
})

test('appends form to body', () => {
  submitHtmlForm(action, method, md5)
  ok(jQuery.fn.appendTo.calledWith('body'), 'appends form to body')
})

test('submits the form', () => {
  const form = getForm()
  ok(jQuery.fn.submit.calledOn(form), 'submits the form')
})

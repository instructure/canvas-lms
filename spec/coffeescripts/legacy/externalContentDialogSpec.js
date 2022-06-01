/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import ExternalContentSuccess from 'ui/features/external_content_success/index.js'
import React from 'react'
import ReactDOM from 'react-dom'

QUnit.module('ExternalContentSuccess', {
  setup() {
    window.$ = window.parent.$ = $
    fakeENV.setup({
      service: 'external_tool_redirect'
    })
  },
  teardown() {
    fakeENV.teardown()
    $('#fixtures').html('')
  }
})

test('without iframe should return `undefined` to getIFrameSrc', () => {
  equal(ExternalContentSuccess.getIFrameSrc(), undefined)

  $('#fixtures').html("<span data-cid='Modal'></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), undefined)

  $('#fixtures').html("<span data-cid='Tray'></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), undefined)
})

test('without iframe should return `undefined` to getLaunchType', () => {
  equal(ExternalContentSuccess.getLaunchType(), undefined)

  $('#fixtures').html("<span data-cid='Modal'></span>")

  equal(ExternalContentSuccess.getLaunchType(), undefined)

  $('#fixtures').html("<span data-cid='Tray'></span>")

  equal(ExternalContentSuccess.getLaunchType(), undefined)
})

test('with iframe should return the `src` to getIFrameSrc', () => {
  $('#fixtures').html("<span data-cid='Modal'><iframe src='http://sample.com'></div></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), 'http://sample.com')

  $('#fixtures').html("<span data-cid='Tray'><iframe src='http://sample.com?a=b'></div></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), 'http://sample.com?a=b')
})

test('with iframe should return the `launch_type` to getLaunchType', () => {
  $('#fixtures').html(
    "<span data-cid='Modal'><iframe src='http://sample.com?launch_type=assignment_index_menu'></div></span>"
  )

  equal(ExternalContentSuccess.getLaunchType(), 'assignment_index_menu')

  $('#fixtures').html(
    "<span data-cid='Tray'><iframe src='http://sample.com?launch_type=assignment_index_menu'></div></span>"
  )

  equal(ExternalContentSuccess.getLaunchType(), 'assignment_index_menu')
})

QUnit.module('ExternalContentSuccess: lti_errormsg', {
  setup() {
    fakeENV.setup({
      service: 'external_tool_redirect'
    })
    ENV.lti_errormsg = 'this is a LTI error message'
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(document.querySelector('#lti_messages_wrapper'))
    $('#fixtures').html('')
  }
})

test('show the "lti_errormsg" message', () => {
  equal(ENV.lti_errormsg, 'this is a LTI error message')
  ExternalContentSuccess.processLtiMessages(ENV, document.querySelector('#fixtures'))

  equal(document.querySelector('#lti_error_message')?.innerText, ENV.lti_errormsg)
})

QUnit.module('ExternalContentSuccess: lti_msg', {
  setup() {
    fakeENV.setup({
      service: 'external_tool_redirect'
    })
    ENV.lti_msg = 'this is a LTI message'
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(document.querySelector('#lti_messages_wrapper'))
    $('#fixtures').html('')
  }
})

test('show the "lti_msg" message', () => {
  equal(ENV.lti_msg, 'this is a LTI message')
  ExternalContentSuccess.processLtiMessages(ENV, document.querySelector('#fixtures'))

  equal(document.querySelector('#lti_message')?.innerText, ENV.lti_msg)
})

QUnit.module('ExternalContentSuccess: lti_msg and lti_errormsg', {
  setup() {
    fakeENV.setup({
      service: 'external_tool_redirect'
    })
    ENV.lti_msg = 'this is a LTI message'
    ENV.lti_errormsg = 'this is a LTI error message'
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(document.querySelector('#lti_messages_wrapper'))
    $('#fixtures').html('')
  }
})

test('show "lti_msg" and "lti_errormsg" messages', () => {
  equal(ENV.lti_msg, 'this is a LTI message')
  equal(ENV.lti_errormsg, 'this is a LTI error message')
  ExternalContentSuccess.processLtiMessages(ENV, document.querySelector('#fixtures'))

  equal(document.querySelector('#lti_message')?.innerText, ENV.lti_msg)
  equal(document.querySelector('#lti_error_message')?.innerText, ENV.lti_errormsg)
})

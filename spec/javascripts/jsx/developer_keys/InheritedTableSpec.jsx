/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import InheritedTable from 'ui/features/developer_keys_v2/react/InheritedTable'
import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('InheritedTable', {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  },
  beforeEach: () => {
    window.ENV = {
      FEATURES: {
        lti_dynamic_registration: true,
        enhanced_developer_keys_tables: true,
      },
    }
  },
  afterEach: () => {
    window.ENV = {}
  },
})

const onDevKeys = [
  {
    id: `1`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
    developer_key_account_binding: {workflow_state: 'off', account_owns_binding: false},
  },
  {id: `2`, api_key: 'abc12345671', created_at: '2012-06-09T20:36:50Z'},
  {
    id: `3`,
    api_key: 'abc12345679',
    created_at: '2012-06-08T20:36:50Z',
    developer_key_account_binding: {workflow_state: 'on', account_owns_binding: false},
  },
]

const offDevKeys = [
  {
    id: `1`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
    developer_key_account_binding: {workflow_state: 'off', account_owns_binding: false},
  },
  {
    id: `3`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
    developer_key_account_binding: {workflow_state: 'off', account_owns_binding: false},
  },
  {id: `2`, api_key: 'abc12345671', created_at: '2012-06-09T20:36:50Z'},
]

function devKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({
    id: `${n}`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
  }))
}

function disabledDevKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({
    id: `${n}`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
    developer_key_account_binding: {workflow_state: 'off', account_owns_binding: false},
  }))
}

function component(keyList, props = {}) {
  return TestUtils.renderIntoDocument(
    <InheritedTable
      label="Test Inherited Table"
      prefix="test"
      store={{dispatch: () => {}}}
      actions={{}}
      developerKeysList={keyList || devKeyList()}
      ctx={{
        params: {
          contextId: '',
        },
      }}
      {...props}
    />
  )
}

function componentNode(keyList = null) {
  return ReactDOM.findDOMNode(component(keyList))
}

test('focuses toggle group if show more button clicked', () => {
  const list = devKeyList()
  const table = component(list)
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusToggleGroup = focusSpy
  table.setFocusCallback()([list[9]])
  ok(focusSpy.called)
})

test('focuses Inherited tab if show more button clicked, and all the toggle buttons are disabled', () => {
  const list = disabledDevKeyList()
  const table = component(list)
  notOk(table.setFocusCallback()([list[9]]))
})

test('focuses On button if show more button clicked and the last non-disabled button is On', () => {
  const table = component(onDevKeys)
  const focusSpy = sinon.spy()
  table['developerKey-2'].focusToggleGroup = focusSpy
  notEqual(table.setFocusCallback()([onDevKeys[2]]), null)
  ok(focusSpy.called)
})

test('focuses Off button if show more button clicked and the last non-disabled button is Off', () => {
  const table = component(offDevKeys)
  const focusSpy = sinon.spy()
  table['developerKey-2'].focusToggleGroup = focusSpy
  notEqual(table.setFocusCallback()([offDevKeys[2]]), null)
  ok(focusSpy.called)
})

test('makes correct screenReader notification if show more button clicked', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.setFocusCallback()([list[9]])
  ok(
    flashSpy.calledWith(
      'Loaded more developer keys. Focus moved to the last enabled developer key in the list.'
    )
  )
  $.screenReaderFlashMessageExclusive = tmp
})

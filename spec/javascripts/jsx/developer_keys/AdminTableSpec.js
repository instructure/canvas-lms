/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute and/or modify under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that will be useful, but WITHOUT ANY
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
import DeveloperKeysTable from 'jsx/developer_keys/AdminTable'
import $ from 'jquery'

QUnit.module('AdminTable',  {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  }
})

const onDevKeys = [
  {id: `1`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z", developer_key_account_binding: {workflow_state: "off",
  account_owns_binding: false}},
  {id: `2`, api_key: "abc12345671", created_at: "2012-06-09T20:36:50Z"},
  {id: `3`, api_key: "abc12345679", created_at: "2012-06-08T20:36:50Z", developer_key_account_binding: {workflow_state: "on",
  account_owns_binding: false}}
]

const offDevKeys = [
  {id: `1`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z", developer_key_account_binding: {workflow_state: "off",
  account_owns_binding: false}},
  {id: `3`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z", developer_key_account_binding: {workflow_state: "off",
  account_owns_binding: false}},
  {id: `2`, api_key: "abc12345671", created_at: "2012-06-09T20:36:50Z"}
]

function devKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({id: `${n}`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}))
}

function disabledDevKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({id: `${n}`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z", 
  developer_key_account_binding: {workflow_state: "off", account_owns_binding: false}}))
}

function component(keyList, inherited, props = {}) {
  return TestUtils.renderIntoDocument(
    <DeveloperKeysTable
      store={{dispatch: () => {}}}
      actions={{}}
      developerKeysList={keyList || devKeyList()}
      ctx={{
        params: {
          contextId: ""
        }
      }}
      inherited={inherited}
      {...props}
    />
  )
}

function componentNode(keyList = null, inherited = false) {
  return ReactDOM.findDOMNode(component(keyList, inherited))
}

test('it does not render the table if no keys are given', () => {
  notOk(componentNode([]))
})

test('does not render the "Owner Email" heading if inherited', () => {
  const node = componentNode(devKeyList(), true)
  equal(node.querySelectorAll('th')[1].innerText, 'Details')
})

test('does render the "Owner Email" heading if not inherited', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[1].innerText, 'Owner Email')
})

test('does not render the "Stats" heading if inherited', () => {
  const node = componentNode(devKeyList(), true)
  notOk(node.querySelectorAll('th')[3])
})

test('does render the "Stats" heading if not inherited', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[3].innerText, 'Stats')
})

test('focuses toggle group if inherited and show more button clicked', () => {
  const list = devKeyList()
  const table = component(list, true)
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusToggleGroup = focusSpy
  table.createSetFocusCallback()([list[9]])
  ok(focusSpy.called)
})

test('focuses Inherited tab if inherited, show more button clicked, and all the toggle buttons are disabled', () => {
  const list = disabledDevKeyList()
  const table = component(list, true)
  notOk(table.createSetFocusCallback()([list[9]]))
})

test('focuses On button if inherited, show more button clicked and the last non-disabled button is On', () => {
  const table = component(onDevKeys, true)
  const focusSpy = sinon.spy()
  table['developerKey-2'].focusToggleGroup = focusSpy
  notEqual(table.createSetFocusCallback()([onDevKeys[2]]), null)
  ok(focusSpy.called)
})

test('focuses Off button if inherited, show more button clicked and the last non-disabled button is Off', () => {
  const table = component(offDevKeys, true)
  const focusSpy = sinon.spy()
  table['developerKey-2'].focusToggleGroup = focusSpy
  notEqual(table.createSetFocusCallback()([offDevKeys[2]]), null)
  ok(focusSpy.called)
})

test('makes correct screenReader notification if inherited and show more button clicked', () => {
  const list = devKeyList()
  const table = component(list, true)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.createSetFocusCallback()([list[9]])
  ok(flashSpy.calledWith("Loaded more developer keys. Focus moved to the name of the last loaded developer key in the list."))
  $.screenReaderFlashMessageExclusive = tmp
})

test('focuses delete icon if not inherited and show more button clicked', () => {
  const list = devKeyList()
  const table = component(list)
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusDeleteLink = focusSpy
  table.createSetFocusCallback()([list[9]])
  ok(focusSpy.called)
})

test('makes correct screenReader notification if not inherited  and show more button clicked', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.createSetFocusCallback()([list[9]])
  ok(flashSpy.calledWith("Loaded more developer keys. Focus moved to the delete button of the last loaded developer key in the list."))
  $.screenReaderFlashMessageExclusive = tmp
})

test('focuses delete icon if not inherited after key deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const focusSpy = sinon.spy()
  table['developerKey-8'].focusDeleteLink = focusSpy
  table.createSetFocusCallback('9')()
  ok(focusSpy.called)
})


test('makes correct screenReader notification if not inherited and key deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.createSetFocusCallback('9')()
  ok(flashSpy.calledWith("Developer key 9 deleted. Focus moved to the delete button of the previous developer key in the list."))
  $.screenReaderFlashMessageExclusive = tmp
})

test('focuses on external button if first item deleted', () => {
  const list = devKeyList()
  const setFocus = sinon.spy()
  const table = component(list, undefined, { setFocus })
  table.createSetFocusCallback('0')()
  ok(setFocus.called)
})


test('makes correct screenReader notification if first item deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.createSetFocusCallback('0')()
  ok(flashSpy.calledWith("Developer key 0 deleted. Focus moved to add developer key button."))
  $.screenReaderFlashMessageExclusive = tmp
})

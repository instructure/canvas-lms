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
import TestUtils from 'react-addons-test-utils'
import DeveloperKeysTable from 'jsx/developer_keys/DeveloperKeysTable'

QUnit.module('DeveloperKeysTable',  {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  }
})

function devKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({id: `${n}`, api_key: "abc12345678", created_at: "2012-06-07T20:36:50Z"}))
}

function component(keyList, inherited) {
  return TestUtils.renderIntoDocument(
    <DeveloperKeysTable
      store={{dispatch: () => {}}}
      actions={{}}
      developerKeysList={keyList || devKeyList()}
      ctx={{}}
      inherited={inherited}
    />
  )
}

function componentNode(keyList = null, inherited = false) {
  return ReactDOM.findDOMNode(component(keyList, inherited))
}

test('it does not render the table if no keys are given', () => {
  notOk(componentNode([]))
})

test('does not render the "User" heading if inherited', () => {
  const node = componentNode(devKeyList(), true)
  equal(node.querySelectorAll('th')[1].innerText, 'Details')
})

test('does render the "User" heading if not inherited', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[1].innerText, 'User')
})

test('does not render the "Stats" heading if inherited', () => {
  const node = componentNode(devKeyList(), true)
  notOk(node.querySelectorAll('th')[3])
})

test('does render the "Stats" heading if not inherited', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[3].innerText, 'Stats')
})

test('focuses name if inherited', () => {
  const table = component(devKeyList(), true)
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusName = focusSpy
  table.focusLastDeveloperKey()
  ok(focusSpy.called)
})

test('focuses delete icon if inherited', () => {
  const table = component(devKeyList())
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusDeleteLink = focusSpy
  table.focusLastDeveloperKey()
  ok(focusSpy.called)
})
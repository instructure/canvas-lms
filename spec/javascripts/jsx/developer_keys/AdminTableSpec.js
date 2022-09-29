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
import AdminTable from 'ui/features/developer_keys_v2/react/AdminTable'
import $ from 'jquery'

QUnit.module('AdminTable', {
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  },
})

function devKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({
    id: `${n}`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
  }))
}

function component(keyList, props = {}) {
  return TestUtils.renderIntoDocument(
    <AdminTable
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

test('it renders table with placeholder text if no keys are given', () => {
  const node = componentNode([])
  equal(node.querySelectorAll('span')[2].innerText, 'Nothing here yet')
})

test('does render the "Owner Email" heading', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[1].innerText, 'Owner Email')
})

test('does render the "Stats" heading', () => {
  const node = componentNode()
  equal(node.querySelectorAll('th')[3].innerText, 'Stats')
})

test('focuses delete icon if show more button clicked', () => {
  const list = devKeyList()
  const table = component(list)
  const focusSpy = sinon.spy()
  table['developerKey-9'].focusDeleteLink = focusSpy
  table.setFocusCallback()([list[9]])
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
      'Loaded more developer keys. Focus moved to the delete button of the last loaded developer key in the list.'
    )
  )
  $.screenReaderFlashMessageExclusive = tmp
})

test('focuses delete icon after key deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const focusSpy = sinon.spy()
  table['developerKey-8'].focusDeleteLink = focusSpy
  table.onDelete('9')
  ok(focusSpy.called)
})

test('makes correct screenReader notification if key deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.onDelete('9')
  ok(
    flashSpy.calledWith(
      'Developer key 9 deleted. Focus moved to the delete button of the previous developer key in the list.'
    )
  )
  $.screenReaderFlashMessageExclusive = tmp
})

test('focuses on external button if first item deleted', () => {
  const list = devKeyList()
  const setFocus = sinon.spy()
  const table = component(list, {setFocus})
  table.onDelete('0')
  ok(setFocus.called)
})

test('makes correct screenReader notification if first item deleted', () => {
  const list = devKeyList()
  const table = component(list)
  const flashSpy = sinon.spy()
  const tmp = $.screenReaderFlashMessageExclusive
  $.screenReaderFlashMessageExclusive = flashSpy
  table.onDelete('0')
  ok(flashSpy.calledWith('Developer key 0 deleted. Focus moved to add developer key button.'))
  $.screenReaderFlashMessageExclusive = tmp
})

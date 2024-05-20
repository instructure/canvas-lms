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
import TestUtils from 'react-dom/test-utils'
import AdminTable from 'ui/features/developer_keys_v2/react/AdminTable'
import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('AdminTable', {
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

function devKeyList(numKeys = 10) {
  return [...Array(numKeys).keys()].map(n => ({
    id: `${n}`,
    api_key: 'abc12345678',
    created_at: '2012-06-07T20:36:50Z',
  }))
}

function component(keyList, props = {}) {
  const c = TestUtils.renderIntoDocument(
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
  c.setState({sortAscending: true})
  return c
}

/**
 * TODO: move to Jest tests found in
 * ui/features/developer_keys_v2/react/__tests__/AdminTable.test.jsx
 */

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
  const table = component(list)
  const focusSpy = sinon.spy()
  table.addDevKeyButton.focus = focusSpy
  table.onDelete('0')
  ok(focusSpy.called)
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

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

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import MoveToDialog from 'ui/features/eportfolio/react/MoveToDialog'

let root
let appRoot
let applicationElement

const mountDialog = (opts = {}) => {
  opts = {
    header: 'This is a dialog',
    source: {label: 'foo', id: '0'},
    destinations: [
      {label: 'bar', id: '1'},
      {label: 'baz', id: '2'},
    ],
    ...opts,
  }

  const element = <MoveToDialog {...opts} />
  // eslint-disable-next-line react/no-render-return-value
  const dialog = ReactDOM.render(element, root)
  return dialog
}

QUnit.module('MoveToDialog', {
  setup() {
    root = document.createElement('div')
    appRoot = document.createElement('div')
    applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.getElementById('fixtures').appendChild(root)
    document.getElementById('fixtures').appendChild(appRoot)
    document.getElementById('fixtures').appendChild(applicationElement)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(root)
    appRoot.removeAttribute('aria-hidden')
    document.getElementById('fixtures').innerHTML = ''
  },
})

test('calls onMove with a destination id when selected', assert => {
  const done = assert.async()
  mountDialog({
    onMove: val => {
      strictEqual(val, '1')
      done()
    },
  })
  const button = document.getElementById('MoveToDialog__move')
  TestUtils.Simulate.click(button)
})

QUnit.skip('does not call onMove when cancelled via close button', assert => {
  const done = assert.async(2)
  mountDialog({
    onMove: _val => {
      ok(false)
    },
    onClose: () => {
      // eslint-disable-next-line jest/valid-expect, qunit/no-global-expect
      expect(0)
      done()
    },
  })
  const button = document.getElementById('MoveToDialog__cancel')
  TestUtils.Simulate.click(button)
})

QUnit.skip('does not fail when no onMove is specified', assert => {
  const done = assert.async(2)
  mountDialog({
    onClose: () => {
      // eslint-disable-next-line jest/valid-expect, qunit/no-global-expect
      expect(0)
      done()
    },
  })
  const button = document.getElementById('MoveToDialog__move')
  TestUtils.Simulate.click(button)
})

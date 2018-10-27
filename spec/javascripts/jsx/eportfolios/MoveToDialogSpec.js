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
import _ from 'lodash'
import MoveToDialog from 'jsx/eportfolios/MoveToDialog'
import assertions from 'helpers/assertions'

let root
let appRoot
let applicationElement

const mountDialog = (opts = {}) => {
  opts = _.extend({}, {
    header: 'This is a dialog',
    source: { label: 'foo', id: '0' },
    destinations: [{ label: 'bar', id: '1' }, { label: 'baz', id: '2' }]
  }, opts)

  const element = <MoveToDialog {...opts} />
  const dialog = ReactDOM.render(element, root)
  return dialog
}

QUnit.module('MoveToDialog', {
  setup () {
    root = document.createElement('div')
    appRoot = document.createElement('div')
    applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.getElementById('fixtures').appendChild(root)
    document.getElementById('fixtures').appendChild(appRoot)
    document.getElementById('fixtures').appendChild(applicationElement)
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(root)
    appRoot.removeAttribute('aria-hidden')
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('includes all destinations in select', () => {
  const dialog = mountDialog()
  const options = TestUtils.scryRenderedDOMComponentsWithTag(dialog.refs.select, 'option')
  ok( options.find((opt) => (opt.label === 'bar')) )
  ok( options.find((opt) => (opt.label === 'baz')) )
})

test('includes "at the bottom" in select', () => {
  const dialog = mountDialog()
  const options = TestUtils.scryRenderedDOMComponentsWithTag(dialog.refs.select, 'option')
  ok( options.find((opt) => (opt.label === '-- At the bottom --')) )
})

test('calls onMove with a destination id when selected', (assert) => {
  const done = assert.async()
  const dialog = mountDialog({
    onMove: (val) => {
      ok(val === '1')
      done()
    }
  })
  const button = document.getElementById('MoveToDialog__move')
  TestUtils.Simulate.click(button)
})

test('does not call onMove when cancelled via close button', (assert) => {
  const done = assert.async()
  const dialog = mountDialog({
    onMove: (val) => {
      ok(false)
    },
    onClose: () => {
      expect(0)
      done()
    }
  })
  const button = document.getElementById('MoveToDialog__cancel')
  TestUtils.Simulate.click(button)
})

test('does not fail when no onMove is specified', (assert) => {
  const done = assert.async()
  const dialog = mountDialog({
    onClose: () => {
      expect(0)
      done()
    }
  })
  const button = document.getElementById('MoveToDialog__move')
  TestUtils.Simulate.click(button)
})

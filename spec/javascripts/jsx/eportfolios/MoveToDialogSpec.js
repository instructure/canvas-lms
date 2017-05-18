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

define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'lodash',
  'jsx/eportfolios/MoveToDialog',
  'helpers/assertions'
], (React, ReactDOM, TestUtils, _, MoveToDialog, assertions) => {

  const fixtures = document.getElementById('fixtures')
  fixtures.innerHTML = '<div id="modalRoot"></div><div id="appRoot"></div>'
  const root = document.getElementById('modalRoot')
  const appRoot= document.getElementById('appRoot')

  const mountDialog = (opts = {}) => {
    opts = _.extend({}, {
      header: 'This is a dialog',
      source: { label: 'foo', id: '0' },
      destinations: [{ label: 'bar', id: '1' }, { label: 'baz', id: '2' }]
    }, opts)

    const element = React.createElement(MoveToDialog, opts)
    const dialog = ReactDOM.render(element, root)
    return dialog
  }

  QUnit.module('MoveToDialog', {
    setup() {
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(root)
      appRoot.removeAttribute('aria-hidden')
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

  test('handles aria-hides app element on open and close', (assert) => {
    const done = assert.async()
    notOk(appRoot.getAttribute('aria-hidden'))
    mountDialog({
      appElement: appRoot
    })

    setTimeout(() => {
      ok(appRoot.getAttribute('aria-hidden'))

      const button = document.getElementById('MoveToDialog__cancel')
      TestUtils.Simulate.click(button)
      notOk(appRoot.getAttribute('aria-hidden'))
      done()
    }, 1)
  })
})

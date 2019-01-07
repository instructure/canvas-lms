/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import CustomColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/CustomColumnHeader'

QUnit.module('GradebookGrid CustomColumnHeader', suiteHooks => {
  let $container
  let component
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      title: 'Notes'
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    component = ReactDOM.render(<CustomColumnHeader {...props} />, $container)
  }

  test('displays the title of the custom column', () => {
    mountComponent()
    ok($container.textContent.includes('Notes'))
  })

  QUnit.module('#handleKeyDown()', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
    })

    function handleKeyDown(which, shiftKey = false) {
      return component.handleKeyDown({which, shiftKey})
    }

    test('does not handle Tab', () => {
      // This allows Grid Support Navigation to handle navigation.
      const returnValue = handleKeyDown(9, false) // Tab
      equal(typeof returnValue, 'undefined')
    })

    test('does not handle Shift+Tab', () => {
      // This allows Grid Support Navigation to handle navigation.
      const returnValue = handleKeyDown(9, true) // Shift+Tab
      equal(typeof returnValue, 'undefined')
    })

    test('does not handle Enter', () => {
      // This allows Grid Support Navigation to handle navigation.
      const returnValue = handleKeyDown(13) // Enter
      equal(typeof returnValue, 'undefined')
    })
  })

  QUnit.module('focus', hooks => {
    let activeElement

    hooks.beforeEach(() => {
      mountComponent()
      activeElement = document.activeElement
    })

    test('#focusAtStart() does not change focus', () => {
      component.focusAtStart()
      strictEqual(document.activeElement, activeElement)
    })

    test('#focusAtEnd() does not change focus', () => {
      component.focusAtEnd()
      strictEqual(document.activeElement, activeElement)
    })
  })
})

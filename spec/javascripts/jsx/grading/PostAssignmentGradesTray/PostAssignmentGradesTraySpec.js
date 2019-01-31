/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {waitForElement, wait} from 'react-testing-library'

import PostAssignmentGradesTray from 'jsx/grading/PostAssignmentGradesTray'

QUnit.module('PostAssignmentGradesTray', suiteHooks => {
  let $container
  let context
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      assignment: {
        id: '2301',
        name: 'Math 1.1'
      },

      onExited: sinon.spy()
    }

    const bindRef = ref => {
      tray = ref
    }
    ReactDOM.render(<PostAssignmentGradesTray ref={bindRef} />, $container)
  })

  suiteHooks.afterEach(async () => {
    if (getTrayElement()) {
      getCloseButton().click()
      await waitForTrayClosed()
    }

    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function getTrayElement() {
    return document.querySelector('[role="dialog"][aria-label="Post grades tray"]')
  }

  function getCloseButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Close')
  }

  async function show() {
    tray.show(context)
    await waitForElement(getTrayElement)
  }

  async function waitForTrayClosed() {
    return wait(() => {
      if (context.onExited.callCount > 0) {
        return
      }
      throw new Error('Tray is still open')
    })
  }

  QUnit.module('#show()', () => {
    test('opens the tray', async () => {
      await show()
      ok(getTrayElement())
    })

    test('displays the name of the assignment', async () => {
      await show()
      const heading = getTrayElement().querySelector('h2')
      equal(heading.textContent, 'Math 1.1')
    })
  })

  QUnit.module('"Close" Button', hooks => {
    hooks.beforeEach(async () => {
      await show()
    })

    test('closes the tray', async () => {
      getCloseButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })
  })
})

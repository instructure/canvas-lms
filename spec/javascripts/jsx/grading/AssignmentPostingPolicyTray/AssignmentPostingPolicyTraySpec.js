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

import AssignmentPostingPolicyTray from 'jsx/grading/AssignmentPostingPolicyTray'

QUnit.module('AssignmentPostingPolicyTray', suiteHooks => {
  let $container
  let context
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      assignment: {
        id: '2301',
        name: 'Math 1.1',
        postManually: false
      },

      onExited: sinon.spy()
    }

    const bindRef = ref => {
      tray = ref
    }
    ReactDOM.render(<AssignmentPostingPolicyTray ref={bindRef} />, $container)
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
    return document.querySelector('[role="dialog"][aria-label="Grade posting policy tray"]')
  }

  function getCloseButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Close')
  }

  function getSaveButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Save')
  }

  function getLabel(text) {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('label')].find($label => $label.textContent.includes(text))
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
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

    test('includes the name of the assignment', async () => {
      await show()
      const heading = getTrayElement().querySelector('h2')
      equal(heading.textContent, 'Grade Posting Policy: Math 1.1')
    })

    test('disables the "Automatically" input for an anonymous assignment', async () => {
      context.assignment.anonymousGrading = true
      await show()
      strictEqual(getInputByLabel('Automatically').disabled, true)
    })

    test('disables the "Automatically" input for a moderated assignment', async () => {
      context.assignment.moderatedGrading = true
      await show()
      strictEqual(getInputByLabel('Automatically').disabled, true)
    })

    test('enables the "Automatically" input if the assignment is not anonymous or moderated', async () => {
      await show()
      strictEqual(getInputByLabel('Automatically').disabled, false)
    })

    test('the "Automatically" input is initally selected if an auto-posted assignment is passed', async () => {
      await show()
      strictEqual(getInputByLabel('Automatically').checked, true)
    })

    test('the "Manually" input is initially selected if a manual-posted assignment is passed', async () => {
      context.assignment.postManually = true
      await show()
      strictEqual(getInputByLabel('Manually').checked, true)
    })

    test('enables the "Save" button if the postManually value has changed', async () => {
      await show()
      getInputByLabel('Manually').click()

      strictEqual(getSaveButton().disabled, false)
    })

    test('disables the "Save" button if the postManually value has not changed', async () => {
      await show()
      getInputByLabel('Manually').click()
      getInputByLabel('Automatically').click()

      strictEqual(getSaveButton().disabled, true)
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

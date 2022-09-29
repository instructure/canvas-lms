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
import {waitFor} from '@testing-library/react'

import AssignmentPostingPolicyTray from 'ui/features/gradebook/react/AssignmentPostingPolicyTray/index'
import * as Api from 'ui/features/gradebook/react/AssignmentPostingPolicyTray/Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

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
        postManually: false,
      },

      onAssignmentPostPolicyUpdated: sinon.spy(),
      onExited: sinon.spy(),
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

  function getCancelButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Cancel')
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

  function show() {
    tray.show(context)
    return waitFor(getTrayElement)
  }

  function waitForTrayClosed() {
    return waitFor(() => {
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

    QUnit.module('when the assignment is moderated', hooks => {
      hooks.beforeEach(() => {
        context.assignment.moderatedGrading = true
      })

      test('disables the "Automatically" input when grades are not published', async () => {
        context.assignment.gradesPublished = false
        await show()
        strictEqual(getInputByLabel('Automatically').disabled, true)
      })

      test('enables the "Automatically" input when grades are published', async () => {
        context.assignment.gradesPublished = true
        await show()
        strictEqual(getInputByLabel('Automatically').disabled, false)
      })

      test('always disables the "Automatically" input when the assignment is anonymous', async () => {
        context.assignment.anonymousGrading = true
        context.assignment.gradesPublished = true
        await show()
        strictEqual(getInputByLabel('Automatically').disabled, true)
      })
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

    test('enables the "Save" button if the postManually value has changed and no request is in progress', async () => {
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

    test('disables the "Save" button if a request is already in progress', async () => {
      let resolveRequest
      const setAssignmentPostPolicyStub = sinon.stub(Api, 'setAssignmentPostPolicy').returns(
        new Promise(resolve => {
          resolveRequest = () => {
            resolve({assignmnentId: '2301', postManually: true})
          }
        })
      )
      await show()
      getInputByLabel('Manually').click()
      getSaveButton().click()

      strictEqual(getSaveButton().disabled, true)
      resolveRequest()
      setAssignmentPostPolicyStub.restore()
    })
  })

  QUnit.module('"Close" Button', hooks => {
    hooks.beforeEach(show)

    test('closes the tray', async () => {
      getCloseButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })
  })

  QUnit.module('"Cancel" button', hooks => {
    hooks.beforeEach(show)

    test('closes the tray', async () => {
      getCancelButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })

    test('is enabled when no request is in progress', () => {
      strictEqual(getCancelButton().disabled, false)
    })

    test('is disabled when a request is in progress', () => {
      let resolveRequest
      const setAssignmentPostPolicyStub = sinon.stub(Api, 'setAssignmentPostPolicy').returns(
        new Promise(resolve => {
          resolveRequest = () => {
            resolve({assignmnentId: '2301', postManually: true})
          }
        })
      )
      getInputByLabel('Manually').click()
      getSaveButton().click()

      strictEqual(getCancelButton().disabled, true)
      resolveRequest()
      setAssignmentPostPolicyStub.restore()
    })
  })

  QUnit.module('"Save" button', hooks => {
    let setAssignmentPostPolicyStub
    let showFlashAlertStub

    hooks.beforeEach(() => {
      return show().then(() => {
        getInputByLabel('Manually').click()

        showFlashAlertStub = sinon.stub(FlashAlert, 'showFlashAlert')
        setAssignmentPostPolicyStub = sinon
          .stub(Api, 'setAssignmentPostPolicy')
          .resolves({assignmentId: '2301', postManually: true})
      })
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
      setAssignmentPostPolicyStub.restore()
      showFlashAlertStub.restore()
    })

    test('calls setAssignmentPostPolicy', () => {
      getSaveButton().click()
      strictEqual(setAssignmentPostPolicyStub.callCount, 1)
    })

    test('passes the assignment ID to setAssignmentPostPolicy', () => {
      getSaveButton().click()
      strictEqual(setAssignmentPostPolicyStub.firstCall.args[0].assignmentId, '2301')
    })

    test('passes the selected postManually value to setAssignmentPostPolicy', () => {
      getSaveButton().click()
      strictEqual(setAssignmentPostPolicyStub.firstCall.args[0].postManually, true)
    })

    QUnit.module('on success', () => {
      const waitForSuccess = async () => {
        await waitFor(() => getTrayElement() == null)
      }

      test('renders a success alert', async () => {
        getSaveButton().click()
        await waitForSuccess()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered alert includes a message referencing the assignment', async () => {
        getSaveButton().click()
        await waitForSuccess()
        const message = 'Success! The post policy for Math 1.1 has been updated.'
        strictEqual(showFlashAlertStub.firstCall.args[0].message, message)
      })

      test('calls the provided onAssignmentPostPolicyUpdated function', async () => {
        getSaveButton().click()
        await waitForSuccess()
        strictEqual(context.onAssignmentPostPolicyUpdated.callCount, 1)
      })

      test('passes the assignmentId to onAssignmentPostPolicyUpdated', async () => {
        getSaveButton().click()
        await waitForSuccess()
        strictEqual(context.onAssignmentPostPolicyUpdated.firstCall.args[0].assignmentId, '2301')
      })

      test('passes the postManually value to onAssignmentPostPolicyUpdated', async () => {
        getSaveButton().click()
        await waitForSuccess()
        strictEqual(context.onAssignmentPostPolicyUpdated.firstCall.args[0].postManually, true)
      })
    })

    QUnit.module('on failure', failureHooks => {
      const waitForFailure = async () => {
        await waitFor(() => FlashAlert.showFlashAlert.callCount > 0)
      }

      failureHooks.beforeEach(() => {
        setAssignmentPostPolicyStub.rejects({error: 'oh no'})
      })

      test('renders an error alert', async () => {
        getSaveButton().click()
        await waitForFailure()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered error alert contains a message', async () => {
        getSaveButton().click()
        await waitForFailure()
        const message = 'An error occurred while saving the assignment post policy'
        strictEqual(showFlashAlertStub.firstCall.args[0].message, message)
      })

      test('the tray remains open', async () => {
        getSaveButton().click()
        await waitForFailure()
        ok(getTrayElement())
      })
    })
  })
})

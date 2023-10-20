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

import HideAssignmentGradesTray from '@canvas/hide-assignment-grades-tray'
import * as Api from '@canvas/hide-assignment-grades-tray/react/Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

QUnit.module('HideAssignmentGradesTray', suiteHooks => {
  let $container
  let context
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      assignment: {
        anonymousGrading: false,
        gradesPublished: true,
        id: '2301',
        name: 'Math 1.1',
      },
      onExited: sinon.spy(),
      onHidden: sinon.spy(),
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
    }

    const bindRef = ref => {
      tray = ref
    }
    ReactDOM.render(<HideAssignmentGradesTray ref={bindRef} />, $container)
  })

  suiteHooks.afterEach(async () => {
    if (getTrayElement()) {
      getCloseIconButton().click()
      await waitForTrayClosed()
    }

    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function getTrayElement() {
    return document.querySelector('[role="dialog"][aria-label="Hide grades tray"]')
  }

  function getCloseButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].filter(
      $button => $button.textContent === 'Close'
    )[1]
  }

  function getCloseIconButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Close')
  }

  function getHideButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Hide')
  }

  function getLabel(text) {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
  }

  function getSectionInput(sectionName) {
    return getInputByLabel(sectionName)
  }

  function getSectionToggleInput() {
    return getInputByLabel('Specific Sections')
  }

  function getSpinner() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('svg')].find(
      $spinner => $spinner.textContent === 'Hiding grades'
    )
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

  QUnit.module('#show()', hooks => {
    hooks.beforeEach(show)

    test('opens the tray', () => {
      ok(getTrayElement())
    })

    test('displays the name of the assignment', () => {
      const heading = getTrayElement().querySelector('h2')
      strictEqual(heading.textContent, 'Math 1.1')
    })

    test('resets the "Specific Sections" toggle', async () => {
      getSectionToggleInput().click()
      await show()
      strictEqual(getSectionToggleInput().checked, false)
    })

    test('resets the selected sections', async () => {
      const hideAssignmentGradesForSectionsStub = sandbox.stub(
        Api,
        'hideAssignmentGradesForSections'
      )
      getSectionToggleInput().click()
      getSectionInput('Sophomores').click()
      await show()
      getSectionToggleInput().click()
      getSectionInput('Freshmen').click()
      getHideButton().click()
      deepEqual(hideAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
    })
  })

  QUnit.module('"Close" Icon Button', hooks => {
    hooks.beforeEach(show)

    test('closes the tray', async () => {
      getCloseIconButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })

    test('calls optional onExited', async () => {
      await show()
      await waitFor(getTrayElement)
      getCloseIconButton().click()
      await waitForTrayClosed()
      const {callCount} = context.onExited
      strictEqual(callCount, 1)
    })
  })

  QUnit.module('"Specific Sections" toggle', hooks => {
    hooks.beforeEach(show)

    test('is present', () => ok(getSectionToggleInput()))

    test('does not display the sections when unchecked', () => {
      notOk(getLabel('Freshmen'))
    })

    test('shows the sections when checked', () => {
      getSectionToggleInput().click()
      ok(getSectionInput('Freshmen'))
    })

    test('is not shown when there are no sections', async () => {
      await show({sections: []})
      notOk(getLabel('Freshmen'))
    })
  })

  QUnit.module('"Close" Button', hooks => {
    hooks.beforeEach(show)

    test('is present', () => ok(getCloseButton()))

    test('closes the tray', async () => {
      getCloseButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })

    test('calls optional onExited', async () => {
      await show()
      await waitFor(getTrayElement)
      getCloseButton().click()
      await waitForTrayClosed()
      const {callCount} = context.onExited
      strictEqual(callCount, 1)
    })
  })

  QUnit.module('"Hide" Button', hooks => {
    let resolveHideAssignmentGradesStatusStub
    let hideAssignmentGradesStub
    let showFlashAlertStub

    const PROGRESS_ID = 23
    const resolveHideAssignmentGradesStatusPromise = {}
    resolveHideAssignmentGradesStatusPromise.promise = new Promise((resolve, reject) => {
      resolveHideAssignmentGradesStatusPromise.resolve = val => {
        resolve(val)
      }
      resolveHideAssignmentGradesStatusPromise.reject = reject
    })

    function waitForHiding() {
      return waitFor(() => resolveHideAssignmentGradesStatusStub.callCount > 0)
    }

    function clickHide() {
      getHideButton().click()
      return waitForHiding()
    }

    hooks.beforeEach(() => {
      resolveHideAssignmentGradesStatusStub = sandbox.stub(Api, 'resolveHideAssignmentGradesStatus')
      hideAssignmentGradesStub = sandbox
        .stub(Api, 'hideAssignmentGrades')
        .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))
      showFlashAlertStub = sandbox.stub(FlashAlert, 'showFlashAlert')

      return show()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
    })

    test('is present', () => ok(getHideButton()))

    test('calls hideAssignmentGrades', async () => {
      await clickHide()
      strictEqual(hideAssignmentGradesStub.callCount, 1)
    })

    test('passes the assignment id to hideAssignmentGrades', async () => {
      await clickHide()
      strictEqual(hideAssignmentGradesStub.firstCall.args[0], '2301')
    })

    test('calls resolveHideAssignmentGradesStatus', async () => {
      await clickHide()
      strictEqual(resolveHideAssignmentGradesStatusStub.callCount, 1)
    })

    test('displays the name of the assignment while hiding grades in is progress', async () => {
      resolveHideAssignmentGradesStatusStub.returns(
        resolveHideAssignmentGradesStatusPromise.promise
      )
      getHideButton().click()
      const heading = getTrayElement().querySelector('h2')
      strictEqual(heading.textContent, 'Math 1.1')
      resolveHideAssignmentGradesStatusPromise.resolve()
      await waitForHiding()
    })

    test('calls onHidden', async () => {
      await clickHide()
      strictEqual(context.onHidden.callCount, 1)
    })

    QUnit.module('pending request', pendingRequestHooks => {
      pendingRequestHooks.beforeEach(() => {
        resolveHideAssignmentGradesStatusStub.returns(
          resolveHideAssignmentGradesStatusPromise.promise
        )
        getHideButton().click()
      })

      pendingRequestHooks.afterEach(async () => {
        resolveHideAssignmentGradesStatusPromise.resolve()
        await waitForHiding()
      })

      test('displays a spinner', () => {
        ok(getSpinner)
      })
    })

    QUnit.module('on success', () => {
      test('renders a success alert', async () => {
        await clickHide()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered success alert contains a message', async () => {
        const successMessage = 'Success! Grades have been hidden for Math 1.1.'
        await clickHide()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
      })

      test('does not render an alert if the tray is launched from SpeedGrader and assignment is anonymous', async () => {
        context.containerName = 'SPEED_GRADER'
        context.assignment.anonymousGrading = true
        await show()
        await clickHide()
        strictEqual(showFlashAlertStub.callCount, 0)
      })

      test('tray is closed after hiding is finished', async () => {
        await clickHide()
        notOk(getTrayElement())
      })
    })

    QUnit.module('on failure', contextHooks => {
      contextHooks.beforeEach(() => {
        hideAssignmentGradesStub.returns(Promise.reject(new Error('An Error Message')))
        return clickHide()
      })

      test('renders an error alert', () => {
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered error alert contains a message', () => {
        const message = 'There was a problem hiding assignment grades.'
        strictEqual(showFlashAlertStub.firstCall.args[0].message, message)
      })

      test('tray remains open', async () => {
        ok(getTrayElement())
      })

      test('spinner is not present', () => {
        notOk(getSpinner())
      })
    })

    QUnit.module('when hiding assignment grades for sections', contextHooks => {
      let hideAssignmentGradesForSectionsStub

      contextHooks.beforeEach(() => {
        hideAssignmentGradesForSectionsStub = sandbox
          .stub(Api, 'hideAssignmentGradesForSections')
          .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))
      })

      test('is not disabled', async () => {
        await show()
        strictEqual(getSectionToggleInput().disabled, false)
      })

      test('is disabled when assignment is anonymously graded', async () => {
        context.assignment.anonymousGrading = true
        await show()
        strictEqual(getSectionToggleInput().disabled, true)
      })

      QUnit.module(
        'given the tray is open and section toggle has been clicked',
        sectionToggleClickedHooks => {
          sectionToggleClickedHooks.beforeEach(() => {
            return show().then(() => {
              getSectionToggleInput().click()
            })
          })

          test('renders an error when no sections are selected', async () => {
            getHideButton().click()
            await waitForHiding()
            strictEqual(showFlashAlertStub.callCount, 1)
          })

          test('the rendered error contains a message when no sections are selected', async () => {
            const errorMessage = 'At least one section must be selected to hide grades by section.'
            getHideButton().click()
            strictEqual(showFlashAlertStub.firstCall.args[0].message, errorMessage)
          })

          test('render a success message when sections are selected and hiding is successful', async () => {
            const successMessage =
              'Success! Grades have been hidden for the selected sections of Math 1.1.'
            getSectionInput('Sophomores').click()
            await clickHide()
            strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
          })

          test('calls hideAssignmentGradesForSections', async () => {
            getSectionInput('Sophomores').click()
            await clickHide()
            strictEqual(hideAssignmentGradesForSectionsStub.callCount, 1)
          })

          test('passes the assignment id to hideAssignmentGradesForSections', async () => {
            getSectionInput('Sophomores').click()
            await clickHide()
            strictEqual(hideAssignmentGradesForSectionsStub.firstCall.args[0], '2301')
          })

          test('passes section ids to hideAssignmentGradesForSections', async () => {
            getSectionInput('Freshmen').click()
            getSectionInput('Sophomores').click()
            await clickHide()
            deepEqual(hideAssignmentGradesForSectionsStub.firstCall.args[1], ['2001', '2002'])
          })

          test('deselecting a section excludes it from being hidden', async () => {
            getSectionInput('Freshmen').click()
            getSectionInput('Sophomores').click()
            getSectionInput('Sophomores').click()
            await clickHide()
            deepEqual(hideAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
          })
        }
      )
    })
  })
})

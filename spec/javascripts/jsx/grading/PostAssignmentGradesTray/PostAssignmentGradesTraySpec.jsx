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

import PostAssignmentGradesTray from '@canvas/post-assignment-grades-tray'
import * as Api from '@canvas/post-assignment-grades-tray/react/Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

QUnit.module('PostAssignmentGradesTray', suiteHooks => {
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
        postManually: false,
      },
      onExited: sinon.spy(),
      onPosted: sinon.spy(),
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
    }

    const bindRef = ref => {
      tray = ref
    }
    ReactDOM.render(<PostAssignmentGradesTray ref={bindRef} />, $container)
  })

  suiteHooks.afterEach(() => {
    let thingToWaitOn
    if (getTrayElement()) {
      getCloseButton().click()
      thingToWaitOn = waitForTrayClosed()
    }
    return Promise.resolve(thingToWaitOn).then(() => {
      ReactDOM.unmountComponentAtNode($container)
      $container.remove()
    })
  })

  function getTrayElement() {
    return document.querySelector('[role="dialog"][aria-label="Post grades tray"]')
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

  function getPostButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Post')
  }

  function getLabel(text) {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function getPostType(type) {
    const $tray = getTrayElement()
    const label = [...$tray.querySelectorAll('label')].find($label =>
      $label.textContent.includes(type)
    )

    return document.getElementById(label.htmlFor)
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
  }

  function getSectionToggleInput() {
    return getInputByLabel('Specific Sections')
  }

  function getSpinner() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('svg')].find(
      $spinner => $spinner.textContent === 'Posting grades'
    )
  }

  function show() {
    tray.show(context)
    return waitFor(getTrayElement)
  }

  function getUnpostedCount() {
    return getUnpostedSummary().querySelector('[id^="Badge_"]')
  }

  function getUnpostedSummary() {
    return getTrayElement().querySelector('div#PostAssignmentGradesTray__Layout__UnpostedSummary')
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
      equal(heading.textContent, 'Math 1.1')
    })

    test('resets the "Specific Sections" toggle', async () => {
      getSectionToggleInput().click()
      await show()
      strictEqual(getSectionToggleInput().checked, false)
    })

    test('resets the selected sections', async () => {
      const postAssignmentGradesForSectionsStub = sinon.stub(Api, 'postAssignmentGradesForSections')
      try {
        getSectionToggleInput().click()
        getInputByLabel('Sophomores').click()
        await show()
        getSectionToggleInput().click()
        getInputByLabel('Freshmen').click()
        getPostButton().click()
        deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
      } finally {
        postAssignmentGradesForSectionsStub.restore()
      }
    })
  })

  QUnit.module('"Close" Button', hooks => {
    hooks.beforeEach(show)

    test('closes the tray', async () => {
      getCloseButton().click()
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
      ok(getInputByLabel('Freshmen'))
    })

    test('is not shown when there are no sections', async () => {
      context.sections = []
      await show()
      notOk(getLabel('Freshmen'))
    })
  })

  QUnit.module('"Close" Icon Button', hooks => {
    hooks.beforeEach(show)

    test('is present', () => ok(getCloseButton()))

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

  QUnit.module('unposted summary', () => {
    QUnit.module('with unposted submissions', () => {
      test('graded submissions without a postedAt are counted', async () => {
        context.submissions = [
          {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
          {postedAt: null, score: 1, workflowState: 'graded'},
          {postedAt: null, score: null, workflowState: 'unsubmitted'},
        ]
        await show()
        strictEqual(getUnpostedCount().textContent, '1')
      })

      test('submissions with postable comments and without a postedAt are counted', async () => {
        context.submissions = [
          {postedAt: new Date().toISOString(), hasPostableComments: true},
          {postedAt: null, score: 1, workflowState: 'graded'},
          {postedAt: null, score: null, workflowState: 'unsubmitted'},
        ]
        await show()
        strictEqual(getUnpostedCount().textContent, '1')
      })
    })

    QUnit.module('with no unposted submissions', unpostedSubmissionsHooks => {
      unpostedSubmissionsHooks.beforeEach(() => {
        context.submissions = [
          {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
          {postedAt: new Date().toISOString(), score: 1, workflowState: 'graded'},
        ]

        return show()
      })

      test('a summary of unposted submissions is not displayed', () => {
        notOk(getUnpostedSummary())
      })
    })
  })

  QUnit.module('"Post" Button', hooks => {
    let resolvePostAssignmentGradesStatusStub
    let postAssignmentGradesStub
    let showFlashAlertStub

    const PROGRESS_ID = 23
    const resolvePostAssignmentGradesStatusPromise = {}
    resolvePostAssignmentGradesStatusPromise.promise = new Promise((resolve, reject) => {
      resolvePostAssignmentGradesStatusPromise.resolve = val => {
        resolve(val)
      }
      resolvePostAssignmentGradesStatusPromise.reject = reject
    })

    async function waitForPosting() {
      await waitFor(() => resolvePostAssignmentGradesStatusStub.callCount > 0)
    }

    async function clickPost() {
      getPostButton().click()
      await waitForPosting()
    }

    hooks.beforeEach(() => {
      resolvePostAssignmentGradesStatusStub = sinon.stub(Api, 'resolvePostAssignmentGradesStatus')
      postAssignmentGradesStub = sinon
        .stub(Api, 'postAssignmentGrades')
        .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))
      showFlashAlertStub = sinon.stub(FlashAlert, 'showFlashAlert')

      return show()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
      showFlashAlertStub.restore()
      postAssignmentGradesStub.restore()
      resolvePostAssignmentGradesStatusStub.restore()
    })

    test('is present', () => ok(getPostButton()))

    test('calls postAssignmentGrades', async () => {
      await clickPost()
      strictEqual(postAssignmentGradesStub.callCount, 1)
    })

    test('passes the assignment id to postAssignmentGrades', async () => {
      await clickPost()
      strictEqual(postAssignmentGradesStub.firstCall.args[0], '2301')
    })

    test('calls resolvePostAssignmentGradesStatus', async () => {
      await clickPost()
      strictEqual(resolvePostAssignmentGradesStatusStub.callCount, 1)
    })

    test('displays the name of the assignment while posting grades is in progress', async () => {
      resolvePostAssignmentGradesStatusStub.returns(
        resolvePostAssignmentGradesStatusPromise.promise
      )
      getPostButton().click()
      const heading = getTrayElement().querySelector('h2')
      strictEqual(heading.textContent, 'Math 1.1')
      resolvePostAssignmentGradesStatusPromise.resolve()
      await waitForPosting()
    })

    test('calls onPosted', async () => {
      await clickPost()
      strictEqual(context.onPosted.callCount, 1)
    })

    QUnit.module('pending request', pendingRequestHooks => {
      pendingRequestHooks.beforeEach(() => {
        resolvePostAssignmentGradesStatusStub.returns(
          resolvePostAssignmentGradesStatusPromise.promise
        )
        getPostButton().click()
      })

      pendingRequestHooks.afterEach(() => {
        resolvePostAssignmentGradesStatusPromise.resolve()
        return waitForPosting()
      })

      test('displays a spinner', () => {
        ok(getSpinner)
      })
    })

    QUnit.module('on success', () => {
      test('renders a success alert', async () => {
        await clickPost()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered success alert contains a message', async () => {
        const successMessage = 'Success! Grades have been posted to everyone for Math 1.1.'
        await clickPost()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
      })

      test('tray is closed after posting is finished', async () => {
        await clickPost()
        notOk(getTrayElement())
      })

      test('does not render an alert if the tray is launched from SpeedGrader and assignment is anonymous', async () => {
        context.containerName = 'SPEED_GRADER'
        context.assignment.anonymousGrading = true
        await show()
        await clickPost()
        strictEqual(showFlashAlertStub.callCount, 0)
      })
    })

    QUnit.module('gradedOnly', contextHooks => {
      contextHooks.beforeEach(() => {
        getPostType('Graded').click()
      })

      test('passes gradedOnly true to postAssignmentGrades when Graded is selected', async () => {
        await clickPost()
        deepEqual(postAssignmentGradesStub.firstCall.args[1], {gradedOnly: true})
      })

      test('passes gradedOnly false to postAssignmentGrades when Graded is not selected', async () => {
        getPostType('Everyone').click()
        await clickPost()
        deepEqual(postAssignmentGradesStub.firstCall.args[1], {gradedOnly: false})
      })

      test('the rendered success alert indicates that posting was only for graded', async () => {
        const successMessage = 'Success! Grades have been posted to everyone graded for Math 1.1.'
        await clickPost()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
      })
    })

    QUnit.module('on failure', contextHooks => {
      contextHooks.beforeEach(() => {
        postAssignmentGradesStub.restore()
        postAssignmentGradesStub = sinon
          .stub(Api, 'postAssignmentGrades')
          .returns(Promise.reject(new Error('ERROR')))
        return clickPost()
      })

      test('renders an error alert', async () => {
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered error alert contains a message', () => {
        const message = 'There was a problem posting assignment grades.'
        strictEqual(showFlashAlertStub.firstCall.args[0].message, message)
      })

      test('tray remains open', () => {
        ok(getTrayElement())
      })

      test('spinner is not present', () => {
        notOk(getSpinner())
      })
    })

    QUnit.module('when posting assignment grades for sections', contextHooks => {
      let postAssignmentGradesForSectionsStub

      contextHooks.beforeEach(() => {
        postAssignmentGradesForSectionsStub = sinon
          .stub(Api, 'postAssignmentGradesForSections')
          .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))
      })

      contextHooks.afterEach(() => {
        postAssignmentGradesForSectionsStub.restore()
      })

      test('is not disabled', async () => {
        await show()
        strictEqual(getSectionToggleInput().disabled, false)
      })

      test('is disabled when assignment is anonymous grade', async () => {
        context.assignment.anonymousGrading = true
        await show()
        strictEqual(getSectionToggleInput().disabled, true)
      })

      QUnit.module(
        'given the tray is open and section toggle has been clicked',
        sectionToggleClickedHooks => {
          sectionToggleClickedHooks.beforeEach(() => {
            return show().then(() => getSectionToggleInput().click())
          })

          test('renders an error when no sections are selected', async () => {
            getPostButton().click()
            await waitForPosting()
            strictEqual(showFlashAlertStub.callCount, 1)
          })

          test('the rendered error contains a message when no sections are selected', () => {
            const errorMessage = 'At least one section must be selected to post grades by section.'
            getPostButton().click()
            strictEqual(showFlashAlertStub.firstCall.args[0].message, errorMessage)
          })

          test('render a success message when sections are selected and posting is successful', async () => {
            const successMessage =
              'Success! Grades have been posted for the selected sections of Math 1.1.'
            getInputByLabel('Sophomores').click()
            await clickPost()
            strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
          })

          test('calls postAssignmentGradesForSections', async () => {
            getInputByLabel('Sophomores').click()
            await clickPost()
            strictEqual(postAssignmentGradesForSectionsStub.callCount, 1)
          })

          test('passes the assignment id to postAssignmentGradesForSections', async () => {
            getInputByLabel('Sophomores').click()
            await clickPost()
            strictEqual(postAssignmentGradesForSectionsStub.firstCall.args[0], '2301')
          })

          test('passes section ids to postAssignmentGradesForSections', async () => {
            getInputByLabel('Freshmen').click()
            getInputByLabel('Sophomores').click()
            await clickPost()
            deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001', '2002'])
          })

          test('deselecting a section excludes it from being posted', async () => {
            getInputByLabel('Freshmen').click()
            getInputByLabel('Sophomores').click()
            getInputByLabel('Sophomores').click()
            await clickPost()
            deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
          })
        }
      )
    })
  })
})

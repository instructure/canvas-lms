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
import * as Api from 'jsx/grading/PostAssignmentGradesTray/Api'
import * as FlashAlert from 'jsx/shared/FlashAlert'

QUnit.module('PostAssignmentGradesTray', suiteHooks => {
  let $container
  let context
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    context = {
      assignment: {
        anonymizeStudents: false,
        gradesPublished: true,
        id: '2301',
        name: 'Math 1.1'
      },
      onExited: sinon.spy(),
      sections: [{id: '2001', name: 'Freshmen'}, {id: '2002', name: 'Sophomores'}]
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
    return [...$tray.querySelectorAll('button')].filter(
      $button => $button.textContent === 'Close'
    )[1]
  }

  function getCloseIconButton() {
    const $tray = getTrayElement()
    return [...$tray.querySelectorAll('button')].filter(
      $button => $button.textContent === 'Close'
    )[0]
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

  function getSectionToggleInput() {
    return document.getElementById(getLabel('Specific Sections').htmlFor)
  }

  function getSectionInput(sectionName) {
    return document.getElementById(getLabel(sectionName).htmlFor)
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

  QUnit.module('#show()', hooks => {
    hooks.beforeEach(async () => {
      await show()
    })

    test('opens the tray', async () => {
      ok(getTrayElement())
    })

    test('displays the name of the assignment', async () => {
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
      getSectionToggleInput().click()
      getSectionInput('Sophomores').click()
      await show()
      getSectionToggleInput().click()
      getSectionInput('Freshmen').click()
      getPostButton().click()
      deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
      postAssignmentGradesForSectionsStub.restore()
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

  QUnit.module('"Specific Sections" toggle', hooks => {
    hooks.beforeEach(async () => {
      await show()
    })

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

  QUnit.module('"Close" Icon Button', hooks => {
    hooks.beforeEach(async () => {
      await show()
    })

    test('closes the tray', async () => {
      getCloseIconButton().click()
      await waitForTrayClosed()
      notOk(getTrayElement())
    })
  })

  QUnit.module('"Post" Button', hooks => {
    const PROGRESS_ID = 23
    let resolvePostAssignmentGradesStatusStub
    let postAssignmentGradesStub
    let showFlashAlertStub

    async function waitTillFinishedPosting() {
      await wait(() => resolvePostAssignmentGradesStatusStub.callCount > 0)
    }

    async function clickPost() {
      getPostButton().click()
      await waitTillFinishedPosting()
    }

    hooks.beforeEach(async () => {
      resolvePostAssignmentGradesStatusStub = sinon.stub(Api, 'resolvePostAssignmentGradesStatus')
      postAssignmentGradesStub = sinon
        .stub(Api, 'postAssignmentGrades')
        .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))
      showFlashAlertStub = sinon.stub(FlashAlert, 'showFlashAlert')

      await show()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
      showFlashAlertStub.restore()
      postAssignmentGradesStub.restore()
      resolvePostAssignmentGradesStatusStub.restore()
    })

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

    test('is disabled while posting grades is in progress', async () => {
      resolvePostAssignmentGradesStatusStub.returns(new Promise(() => {}))
      getPostButton().click()
      strictEqual(getPostButton().disabled, true)
      const callCount = resolvePostAssignmentGradesStatusStub.callCount
      resolvePostAssignmentGradesStatusStub.returns(Promise.resolve({}))
      await wait(() => resolvePostAssignmentGradesStatusStub.callCount > callCount)
    })

    test('is disabled when assignment has not yet had grades published', async () => {
      context.assignment.gradesPublished = false
      await show()
      strictEqual(getPostButton().disabled, true)
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
      })

      test('renders an error alert', async () => {
        await clickPost()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered error alert contains a message', async () => {
        const message = 'There was a problem posting assignment grades.'
        await clickPost()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, message)
      })

      test('tray remains open', async () => {
        await clickPost()
        ok(getTrayElement())
      })

      test('"Post" button is re-enabled', async () => {
        await clickPost()
        strictEqual(getPostButton().disabled, false)
      })
    })

    QUnit.module('when posting assignment grades for sections', contextHooks => {
      let postAssignmentGradesForSectionsStub

      contextHooks.beforeEach(async () => {
        postAssignmentGradesForSectionsStub = sinon
          .stub(Api, 'postAssignmentGradesForSections')
          .returns(Promise.resolve({id: PROGRESS_ID, workflowState: 'queued'}))

        await show()
        getSectionToggleInput().click()
      })

      contextHooks.afterEach(() => {
        postAssignmentGradesForSectionsStub.restore()
      })

      test('is disabled when assignment is anonymous grading', async () => {
        context.assignment.anonymizeStudents = true
        await show()
        strictEqual(getSectionToggleInput().disabled, true)
      })

      test('renders an error when no sections are selected', async () => {
        getPostButton().click()
        await waitTillFinishedPosting()
        strictEqual(showFlashAlertStub.callCount, 1)
      })

      test('the rendered error contains a message when no sections are selected', async () => {
        const errorMessage = 'At least one section must be selected to post grades by section.'
        getPostButton().click()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, errorMessage)
      })

      test('render a success message when sections are selected and posting is successful', async () => {
        const successMessage =
          'Success! Grades have been posted for the selected sections of Math 1.1.'
        getSectionInput('Sophomores').click()
        await clickPost()
        strictEqual(showFlashAlertStub.firstCall.args[0].message, successMessage)
      })

      test('calls postAssignmentGradesForSections', async () => {
        getSectionInput('Sophomores').click()
        await clickPost()
        strictEqual(postAssignmentGradesForSectionsStub.callCount, 1)
      })

      test('passes the assignment id to postAssignmentGradesForSections', async () => {
        getSectionInput('Sophomores').click()
        await clickPost()
        strictEqual(postAssignmentGradesForSectionsStub.firstCall.args[0], '2301')
      })

      test('passes section ids to postAssignmentGradesForSections', async () => {
        getSectionInput('Freshmen').click()
        getSectionInput('Sophomores').click()
        await clickPost()
        deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001', '2002'])
      })

      test('deselecting a section excludes it from being posted', async () => {
        getSectionInput('Freshmen').click()
        getSectionInput('Sophomores').click()
        getSectionInput('Sophomores').click()
        await clickPost()
        deepEqual(postAssignmentGradesForSectionsStub.firstCall.args[1], ['2001'])
      })
    })
  })
})

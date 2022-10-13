/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import AssessmentAuditTray from 'ui/features/speed_grader/react/AssessmentAuditTray/index'
import Api from 'ui/features/speed_grader/react/AssessmentAuditTray/Api'

QUnit.module('AssessmentAuditTray', suiteHooks => {
  let $container
  let api
  let context
  let onEntered
  let onExited
  let props
  let resolveAuditTrail
  let tray

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    props = {}
    onEntered = promiseProp('onEntered')
    onExited = promiseProp('onExited')

    api = new Api()
    const promise = new Promise(resolve => {
      resolveAuditTrail = resolve
    })
    sinon.stub(api, 'loadAssessmentAuditTrail').returns(promise)

    context = {
      assignment: {
        gradesPublishedAt: '2015-05-04T12:00:00.000Z',
        id: '2301',
        pointsPossible: 10,
      },
      courseId: '1201',
      submission: {
        id: '2501',
        score: 9.5,
      },
    }

    renderTray()
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function promiseProp(propName) {
    return new Promise(resolve => {
      props[propName] = resolve
    })
  }

  function renderTray() {
    ReactDOM.render(
      <AssessmentAuditTray
        api={api}
        ref={ref => {
          tray = ref
        }}
        {...props}
      />,
      $container
    )
  }

  function getTrayContainer() {
    return document.querySelector('[role="dialog"][aria-label="Assessment audit tray"]')
  }

  function getAssessmentSummaryContainer() {
    return getTrayContainer().querySelector('section')
  }

  function getAssessmentAuditTrailContainer() {
    return getTrayContainer().querySelector('#assessment-audit-trail')
  }

  function getCloseButton() {
    const $tray = getTrayContainer()
    return [...$tray.querySelectorAll('button')].find($button => $button.textContent === 'Close')
  }

  QUnit.module('#show()', () => {
    test('opens the tray', async () => {
      tray.show(context)
      await onEntered
      ok(getTrayContainer())
    })

    test('loads the assessment audit trail', async () => {
      tray.show(context)
      await onEntered
      strictEqual(api.loadAssessmentAuditTrail.callCount, 1)
    })

    QUnit.module('when requesting the assessment audit trail', contextHooks => {
      contextHooks.beforeEach(() => {
        tray.show(context)
        return onEntered
      })

      test('includes the given course id', () => {
        const [courseId] = api.loadAssessmentAuditTrail.lastCall.args
        strictEqual(courseId, '1201')
      })

      test('includes the given assignment id', () => {
        const [, assignmentId] = api.loadAssessmentAuditTrail.lastCall.args
        strictEqual(assignmentId, '2301')
      })

      test('includes the given submission id', () => {
        const [, , submissionId] = api.loadAssessmentAuditTrail.lastCall.args
        strictEqual(submissionId, '2501')
      })
    })

    QUnit.module('when the assessment audit trail is loading', contextHooks => {
      contextHooks.beforeEach(() => {
        tray.show(context)
        return onEntered
      })

      test('does not show the assessment summary', () => {
        notOk(getAssessmentSummaryContainer())
      })

      test('does not show the assessment audit trail', () => {
        notOk(getAssessmentAuditTrailContainer())
      })

      test('displays a loading message', () => {
        ok(getTrayContainer().textContent.includes('Loading assessment audit trail'))
      })
    })

    QUnit.module('when the assessment audit trail loads', contextHooks => {
      contextHooks.beforeEach(() => {
        tray.show(context)
        return onEntered.then(() => {
          const auditEvents = [
            {
              assignmentId: '2301',
              canvadocId: null,
              createdAt: new Date('2018-08-28T16:46:44Z'),
              eventType: 'grades_posted',
              id: '4901',
              payload: {
                grades_published_at: [null, '2018-08-28T16:46:43Z'],
              },
              submissionId: '2501',
              userId: '1101',
            },
          ]
          const users = [{id: '1101', name: 'A mildly discomfited grader', role: 'grader'}]
          const externalTools = [{id: '21', name: 'Bulldog Tool', role: 'grader'}]
          const quizzes = [{id: '123', name: 'Unicorns', role: 'grader'}]
          resolveAuditTrail({auditEvents, users, externalTools, quizzes})
        })
      })

      test('shows the assessment summary', () => {
        ok(getAssessmentSummaryContainer())
      })

      test('shows the assessment audit trail', () => {
        ok(getAssessmentAuditTrailContainer())
      })

      test('does not display a loading message', () => {
        notOk(getTrayContainer().textContent.includes('Loading assessment audit trail'))
      })
    })
  })

  test('closes when the "Close" button is clicked', async () => {
    tray.show(context)
    await onEntered
    getCloseButton().click()
    await onExited
    notOk(getTrayContainer())
  })
})

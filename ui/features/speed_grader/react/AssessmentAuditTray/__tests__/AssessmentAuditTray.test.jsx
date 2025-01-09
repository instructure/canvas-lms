/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import AssessmentAuditTray from '../index'
import Api from '../Api'

describe('AssessmentAuditTray', () => {
  let container
  let api
  let context
  let onEntered
  let onExited
  let trayRef

  const defaultContext = {
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

  const renderTray = (props = {}) => {
    const rendered = render(
      <AssessmentAuditTray
        api={api}
        ref={ref => {
          trayRef = ref
        }}
        {...props}
      />,
      {container},
    )
    return rendered
  }

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)

    api = new Api()
    jest.spyOn(api, 'loadAssessmentAuditTrail').mockImplementation(
      () =>
        new Promise(resolve => {
          onEntered = resolve
        }),
    )

    context = {...defaultContext}
    onExited = jest.fn()
  })

  afterEach(() => {
    container.remove()
  })

  const getTrayContainer = () =>
    screen.queryByRole('dialog', {name: 'Assessment audit tray', hidden: true})
  const getAssessmentSummaryContainer = () => screen.queryByRole('section')
  const getAssessmentAuditTrailContainer = () => screen.queryByTestId('assessment-audit-trail')
  const getCloseButton = () => screen.queryByRole('button', {name: 'Close', hidden: true})

  describe('#show()', () => {
    it('opens the tray', async () => {
      renderTray()
      trayRef.show(context)
      await waitFor(() => {
        expect(getTrayContainer()).toBeInTheDocument()
      })
    })

    it('loads the assessment audit trail', async () => {
      renderTray()
      trayRef.show(context)
      await waitFor(() => {
        expect(api.loadAssessmentAuditTrail).toHaveBeenCalled()
      })
    })

    describe('when requesting the assessment audit trail', () => {
      beforeEach(async () => {
        renderTray()
        trayRef.show(context)
        await waitFor(() => {
          expect(getTrayContainer()).toBeInTheDocument()
        })
      })

      it('includes the given course id', () => {
        expect(api.loadAssessmentAuditTrail).toHaveBeenCalledWith(
          '1201',
          expect.anything(),
          expect.anything(),
        )
      })

      it('includes the given assignment id', () => {
        expect(api.loadAssessmentAuditTrail).toHaveBeenCalledWith(
          expect.anything(),
          '2301',
          expect.anything(),
        )
      })

      it('includes the given submission id', () => {
        expect(api.loadAssessmentAuditTrail).toHaveBeenCalledWith(
          expect.anything(),
          expect.anything(),
          '2501',
        )
      })
    })

    describe('when the assessment audit trail is loading', () => {
      beforeEach(async () => {
        renderTray()
        trayRef.show(context)
        await waitFor(() => {
          expect(getTrayContainer()).toBeInTheDocument()
        })
      })

      it('does not show the assessment summary', () => {
        expect(getAssessmentSummaryContainer()).not.toBeInTheDocument()
      })

      it('does not show the assessment audit trail', () => {
        expect(getAssessmentAuditTrailContainer()).not.toBeInTheDocument()
      })

      it('displays a loading message', () => {
        expect(screen.getByText('Loading assessment audit trail')).toBeInTheDocument()
      })
    })

    describe('when the assessment audit trail loads', () => {
      const auditTrailData = {
        auditEvents: [
          {
            id: '4901',
            createdAt: new Date('2018-08-28T16:46:44Z'),
            eventType: 'submission_updated',
            userId: '1101',
            payload: {
              grade: '10',
              score: 10,
            },
          },
        ],
        users: [
          {
            id: '1101',
            name: 'A mildly discomfited grader',
            role: 'grader',
          },
        ],
        externalTools: [],
        quizzes: [],
      }

      beforeEach(async () => {
        renderTray()
        trayRef.show(context)
        await waitFor(() => {
          expect(getTrayContainer()).toBeInTheDocument()
        })

        onEntered(auditTrailData)
      })

      it('shows the assessment audit trail', async () => {
        await waitFor(() => {
          expect(getAssessmentAuditTrailContainer()).toBeInTheDocument()
        })
      })

      it('does not display a loading message', async () => {
        await waitFor(() => {
          expect(screen.queryByText('Loading assessment audit trail')).not.toBeInTheDocument()
        })
      })
    })
  })

  it('closes when the "Close" button is clicked', async () => {
    const user = userEvent.setup()
    renderTray({onExited})
    trayRef.show(context)

    await waitFor(() => {
      expect(getTrayContainer()).toBeInTheDocument()
    })

    await user.click(getCloseButton())
    await waitFor(() => {
      expect(onExited).toHaveBeenCalled()
    })
  })
})

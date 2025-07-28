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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import CreatorEventGroup from '../CreatorEventGroup'
import {
  buildAssignmentCreatedEvent,
  buildAssignmentUpdatedEvent,
  buildEvent,
} from '../../../__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from '../../../buildAuditTrail'

describe('AssessmentAuditTray CreatorEventGroup', () => {
  let auditEvents
  let externalTools
  let quizzes
  let users
  let props

  beforeEach(() => {
    auditEvents = [
      buildAssignmentCreatedEvent({id: '4901', createdAt: '2018-09-01T12:00:00Z'}),
      buildEvent({id: '4902', userId: '1101', createdAt: '2018-09-02T12:00:00Z'}),
      buildEvent({id: '4903', userId: '1101', createdAt: '2018-09-02T12:00:00Z'}),
    ]
    users = [{id: '1101', name: 'Adam Jones', role: 'final_grader'}]
    externalTools = [{id: '21', name: 'Bulldog Tool', role: 'grader'}]
    quizzes = [{id: '123', name: 'Unicorns', role: 'grader'}]
  })

  const renderComponent = () => {
    const auditTrail = buildAuditTrail({auditEvents, users, externalTools, quizzes})
    props = {creatorEventGroup: auditTrail.creatorEventGroups[0]}
    return render(<CreatorEventGroup {...props} />)
  }

  it('displays the creator name', () => {
    renderComponent()
    expect(screen.getByRole('heading', {level: 3})).toHaveTextContent('Adam Jones')
  })

  it('displays the creator role', () => {
    renderComponent()
    expect(screen.getByRole('heading', {level: 3})).toHaveTextContent('(Final Grader)')
  })

  describe('Non-anonymous action notification', () => {
    describe('when the creator acted while student anonymity was disabled', () => {
      beforeEach(() => {
        const event = buildAssignmentUpdatedEvent(
          {createdAt: '2018-09-01T13:00:00Z', id: '4904'},
          {anonymous_grading: [true, false]},
        )
        auditEvents.splice(1, 0, event)
      })

      it('displays a warning icon', () => {
        renderComponent()
        expect(screen.getByTestId('warning-icon')).toBeInTheDocument()
      })

      it('displays a tooltip', async () => {
        renderComponent()
        const warningIcon = screen.getByTestId('warning-icon')
        await userEvent.hover(warningIcon)
        expect(
          await screen.findByText(`${users[0].name} performed actions while anonymous was off`),
        ).toBeInTheDocument()
      })
    })

    describe('when the creator acted while student anonymity was enabled', () => {
      it('does not display a warning icon', () => {
        renderComponent()
        expect(screen.queryByTestId('warning-icon')).not.toBeInTheDocument()
      })

      it('does not display a tooltip', () => {
        renderComponent()
        expect(screen.queryByRole('tooltip')).not.toBeInTheDocument()
      })
    })
  })

  describe('Toggle Details button', () => {
    it('is labeled with the creator name', () => {
      renderComponent()
      expect(screen.getByRole('button')).toHaveTextContent('Assessment audit events for Adam Jones')
    })

    it('expands the collapsed details section when clicked', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button'))
      const dateEventGroups = screen.getByTestId('date-event-groups')
      expect(dateEventGroups.children).toHaveLength(2)
    })

    it('collapses the expanded details section when clicked', async () => {
      renderComponent()
      const button = screen.getByRole('button')
      await userEvent.click(button)
      await userEvent.click(button)
      const dateEventGroups = screen.queryByTestId('date-event-groups')
      expect(dateEventGroups).not.toBeInTheDocument()
    })
  })

  describe('date event groups section', () => {
    it('is empty when collapsed', () => {
      renderComponent()
      const headings = screen.queryAllByRole('heading', {level: 4})
      expect(headings).toHaveLength(0)
    })

    it('displays a date event heading for each unique date when expanded', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button'))
      const headings = screen.getAllByRole('heading', {level: 4})
      expect(headings).toHaveLength(2)
    })
  })
})

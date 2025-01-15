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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import AuditEvent from '../AuditEvent'
import {auditEventStudentAnonymityStates} from '../../../AuditTrailHelpers'
import {buildEvent} from '../../../__tests__/AuditTrailSpecHelpers'

const {NA, OFF, ON, TURNED_OFF, TURNED_ON} = auditEventStudentAnonymityStates

describe('AuditEvent', () => {
  let defaultProps

  beforeEach(() => {
    defaultProps = {
      auditEvent: buildEvent({eventType: 'grades_posted'}),
      studentAnonymity: ON,
    }
  })

  const renderAuditEvent = (props = {}) => {
    return render(<AuditEvent {...defaultProps} {...props} />)
  }

  it('displays the label for the audit event', () => {
    const {getByText} = renderAuditEvent()
    expect(getByText('Grades posted')).toBeInTheDocument()
  })

  describe('Anonymity notification', () => {
    const OFF_MESSAGE = 'Action was not anonymous'
    const TURNED_OFF_MESSAGE = 'Anonymous was turned off'

    beforeEach(() => {
      defaultProps.auditEvent = buildEvent({eventType: 'student_anonymity_updated'})
    })

    describe('when student anonymity was on', () => {
      it('does not display a notification badge or tooltip', () => {
        const {queryByTestId} = renderAuditEvent({studentAnonymity: ON})
        expect(queryByTestId('audit_event_badge')).not.toBeInTheDocument()
      })
    })

    describe('when student anonymity was turned on', () => {
      it('does not display a notification badge or tooltip', () => {
        const {queryByTestId} = renderAuditEvent({studentAnonymity: TURNED_ON})
        expect(queryByTestId('audit_event_badge')).not.toBeInTheDocument()
      })
    })

    describe('when student anonymity was off', () => {
      it('displays a notification badge with correct tooltip', async () => {
        const {getByTestId, getByText} = renderAuditEvent({studentAnonymity: OFF})
        const badge = getByTestId('audit_event_badge')
        expect(badge).toBeInTheDocument()

        // Hover over the badge to show tooltip
        await userEvent.hover(badge)
        expect(getByText(OFF_MESSAGE)).toBeInTheDocument()
      })
    })

    describe('when student anonymity was turned off', () => {
      it('displays a notification badge with correct tooltip', async () => {
        const {getByTestId, getByText} = renderAuditEvent({studentAnonymity: TURNED_OFF})
        const badge = getByTestId('audit_event_badge')
        expect(badge).toBeInTheDocument()

        // Hover over the badge to show tooltip
        await userEvent.hover(badge)
        expect(getByText(TURNED_OFF_MESSAGE)).toBeInTheDocument()
      })
    })

    describe('when student anonymity was not used', () => {
      it('does not display a notification badge or tooltip', () => {
        const {queryByTestId} = renderAuditEvent({studentAnonymity: NA})
        expect(queryByTestId('audit_event_badge')).not.toBeInTheDocument()
      })
    })
  })

  describe('snippet', () => {
    it('displays snippet for audit events with snippets', () => {
      const comment = 'Good job.'
      const {getByText} = renderAuditEvent({
        auditEvent: buildEvent({eventType: 'submission_comment_created'}, {comment}),
      })
      expect(getByText(comment)).toBeInTheDocument()
    })

    it('does not display snippet for events without snippets', () => {
      const {container} = renderAuditEvent({
        auditEvent: buildEvent({eventType: 'unknown'}),
      })
      expect(container.querySelector('p')).not.toBeInTheDocument()
    })
  })
})

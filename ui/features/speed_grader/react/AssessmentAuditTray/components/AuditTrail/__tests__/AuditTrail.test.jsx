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

import AuditTrail from '../index'
import {buildEvent} from '../../../__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from '../../../buildAuditTrail'

describe('AssessmentAuditTray AuditTrail', () => {
  const defaultProps = () => {
    const auditEvents = [
      buildEvent({id: '4901', userId: '1103'}),
      buildEvent({id: '4902', userId: '1101'}),
      buildEvent({id: '4903', userId: '1102'}),
      buildEvent({id: '4904', userId: '1104'}),
      buildEvent(
        {id: '4905', eventType: 'submission_updated', userId: '1101'},
        {grade: [null, 'A']},
      ),
    ]

    const users = [
      {id: '1101', name: 'A sedulous pupil', role: 'student'},
      {id: '1102', name: 'A quizzical administrator', role: 'administrator'},
      {id: '1103', name: 'A querulous final-grader', role: 'final_grader'},
    ]

    const externalTools = []
    const quizzes = []

    return {
      auditTrail: buildAuditTrail({auditEvents, users, externalTools, quizzes}),
    }
  }

  it('displays a creator event group for each distinct creator', () => {
    render(<AuditTrail {...defaultProps()} />)
    const creatorGroups = screen.getAllByRole('button', {
      name: /Assessment audit events for/,
    })
    expect(creatorGroups).toHaveLength(4)
  })

  it('displays the name of the creator in the header', () => {
    render(<AuditTrail {...defaultProps()} />)
    const heading = screen.getByRole('heading', {
      name: /A sedulous pupil \(Student\)/,
    })
    expect(heading).toBeInTheDocument()
  })

  it('displays the role of the creator in the header', () => {
    render(<AuditTrail {...defaultProps()} />)
    const heading = screen.getByRole('heading', {
      name: /\(Student\)/,
    })
    expect(heading).toBeInTheDocument()
  })

  it('displays "Unknown User" when the related user is not loaded', () => {
    render(<AuditTrail {...defaultProps()} />)
    const heading = screen.getByRole('heading', {
      name: /Unknown User \(Unknown Role\)/,
    })
    expect(heading).toBeInTheDocument()
  })
})

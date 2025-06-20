/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {SubmissionProgress} from '../components/SubmissionProgress'
import {WORKFLOW_STATES, SUBMISSION_STATES} from '../constants/submissionStates'
import {Submission} from '../../assignments_show_student'

describe('SubmissionProgress', () => {
  const defaultProps = {
    state: WORKFLOW_STATES[SUBMISSION_STATES.IN_PROGRESS],
    maxValue: 3,
    submission: {
      submittedAt: null,
      proxySubmitter: null,
    } as Submission,
    context: {latestSubmission: WORKFLOW_STATES[SUBMISSION_STATES.IN_PROGRESS]},
  }

  it('renders title text correctly', () => {
    render(<SubmissionProgress {...defaultProps} />)
    const title = screen.getByText('In Progress')

    expect(title).toBeInTheDocument()
  })

  it('renders subtitle when provided', () => {
    render(<SubmissionProgress {...defaultProps} />)
    const subtitle = screen.getByText('NEXT UP: Submit Assignment')

    expect(subtitle).toBeInTheDocument()
  })

  it('renders proxy submitter info when present', () => {
    const props = {
      ...defaultProps,
      submission: {
        ...defaultProps.submission,
        proxySubmitter: 'John Doe',
      },
    }

    render(<SubmissionProgress {...props} />)
    const proxyInfo = screen.getByText('by John Doe')

    expect(proxyInfo).toBeInTheDocument()
  })

  it('renders submitted state with date', () => {
    const submittedAt = '2025-05-29T10:00:00Z'
    const props = {
      state: WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED],
      maxValue: 3,
      submission: {
        submittedAt,
        proxySubmitter: null,
      } as Submission,
      context: {latestSubmission: WORKFLOW_STATES[SUBMISSION_STATES.SUBMITTED]},
    }

    render(<SubmissionProgress {...props} />)
    const title = screen.getAllByText(/Submitted on May 29, 2025/i)

    expect(title).toHaveLength(2)
  })
})

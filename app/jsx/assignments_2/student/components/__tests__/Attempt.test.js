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
import Attempt from '../Attempt'
import {mockAssignment, mockSubmission} from '../../test-utils'
import React from 'react'
import {render} from 'react-testing-library'

describe('unlimited attempts', () => {
  it('renders correctly', () => {
    const submission = mockSubmission()
    submission.attempt = 1
    const {getByText} = render(<Attempt assignment={mockAssignment()} submission={submission} />)
    expect(getByText('Attempt 1')).toBeInTheDocument()
  })

  it('renders the curent submission attempt', () => {
    const submission = mockSubmission()
    submission.attempt = 3
    const {getByText} = render(<Attempt assignment={mockAssignment()} submission={submission} />)
    expect(getByText('Attempt 3')).toBeInTheDocument()
  })
})

describe('limited attempts', () => {
  it('renders attempt', () => {
    const assignment = mockAssignment()
    const submission = mockSubmission()
    assignment.allowedAttempts = 4
    submission.attempt = 2
    const {getByText} = render(<Attempt assignment={assignment} submission={submission} />)
    expect(getByText('Attempt 2 of 4')).toBeInTheDocument()
  })
})

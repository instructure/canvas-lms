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
import {mockAssignmentAndSubmission} from '../../mocks'
import React from 'react'
import {render} from '@testing-library/react'

describe('unlimited attempts', () => {
  it('renders correctly', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {attempt: 1}})
    const {getByText} = render(<Attempt {...props} />)
    expect(getByText('Attempt 1')).toBeInTheDocument()
  })

  it('renders attempt 0 as attempt 1', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {attempt: 0}})
    const {getByText} = render(<Attempt {...props} />)
    expect(getByText('Attempt 1')).toBeInTheDocument()
  })

  it('renders the current submission attempt', async () => {
    const props = await mockAssignmentAndSubmission({Submission: {attempt: 3}})
    const {getByText} = render(<Attempt {...props} />)
    expect(getByText('Attempt 3')).toBeInTheDocument()
  })
})

describe('limited attempts', () => {
  it('renders attempt', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {attempt: 2},
      Assignment: {allowedAttempts: 4}
    })
    const {getByText} = render(<Attempt {...props} />)
    expect(getByText('Attempt 2 of 4')).toBeInTheDocument()
  })
})

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
import {mockAssignment} from '@canvas/assignments/graphql/studentMocks'
import AssignmentDetails from '../AssignmentDetails'
import {render} from '@testing-library/react'

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

it('renders the title', async () => {
  const assignment = await mockAssignment({
    Assignment: {name: 'Egypt Economy Research'},
  })
  const {getByText} = render(<AssignmentDetails assignment={assignment} />)
  expect(getByText('Egypt Economy Research')).toBeInTheDocument()
})

it('renders the due date if dueAt is set', async () => {
  const assignment = await mockAssignment({
    Assignment: {dueAt: '2016-07-11T18:00:00-01:00'},
  })

  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} />)
  // Reason why this is showing up twice is once for screenreader content and again for regular content
  // Also, notice that it handles timezone differences here, with the `-01:00` offset
  expect(queryAllByText('Due: Mon Jul 11, 2016 7:00pm')).toHaveLength(2)
  expect(queryAllByText('7/11/2016')).toHaveLength(1)
})

it('does not render a due date if there is no dueAt set', async () => {
  const assignment = await mockAssignment()
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} />)
  expect(queryAllByText('Available Jul 11, 2016 7:00pm')).toHaveLength(0)
})

it('renders the peer name when peer review mode is ON', async () => {
  const assignment = await mockAssignment()

  assignment.env.peerReviewModeEnabled = true
  assignment.env.peerDisplayName = 'John Connor'
  const {getByText} = render(<AssignmentDetails assignment={assignment} />)
  expect(getByText(/John Connor/)).toBeInTheDocument()
})

it('does not render the peer name when peer review mode is OFF', async () => {
  const assignment = await mockAssignment()

  assignment.env.peerReviewModeEnabled = false
  assignment.env.peerDisplayName = 'John Connor'
  const {queryByText} = render(<AssignmentDetails assignment={assignment} />)
  expect(queryByText(/John Connor/)).not.toBeInTheDocument()
})

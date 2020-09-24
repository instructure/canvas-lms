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

import {mockAssignment} from '../../mocks'
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

it('renders title correctly', async () => {
  const assignment = await mockAssignment({
    Assignment: {name: 'Egypt Economy Research'}
  })
  const {getAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  expect(getAllByText('Egypt Economy Research')).toHaveLength(1)
})

it('renders title correctly when sticky', async () => {
  const assignment = await mockAssignment({
    Assignment: {name: 'Egypt Economy Research'}
  })
  const {getAllByText} = render(<AssignmentDetails assignment={assignment} isSticky />)
  expect(getAllByText('Egypt Economy Research')).toHaveLength(1)
})

it('does not render AvailabilityDates when sticky', async () => {
  const assignment = await mockAssignment({
    Assignment: {
      unlockAt: '2016-07-11T18:00:00-01:00',
      lockAt: '2016-11-11T18:00:00-01:00'
    }
  })
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky />)
  expect(queryAllByText('Available: Jul 11, 2016 7:00pm')).toHaveLength(0)
})

it('renders AvailabilityDates when not sticky', async () => {
  const assignment = await mockAssignment({
    Assignment: {
      unlockAt: '2016-07-11T18:00:00-01:00',
      lockAt: '2016-11-11T18:00:00-01:00'
    }
  })
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  // Reason why this is showing up twice is once for screenreader content and again for regular content
  expect(queryAllByText('Available: Jul 11, 2016 7:00pm')).toHaveLength(2)
})

it('renders date correctly', async () => {
  const assignment = await mockAssignment({
    Assignment: {dueAt: '2016-07-11T18:00:00-01:00'}
  })

  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  // Reason why this is showing up twice is once for screenreader content and again for regular content
  // Also, notice that it handles timezone differences here, with the `-01:00` offset
  expect(queryAllByText('Due: Mon Jul 11, 2016 7:00pm')).toHaveLength(2)
  expect(queryAllByText('7/11/2016')).toHaveLength(1)
})

it('does not render a date if there is no dueAt set', async () => {
  const assignment = await mockAssignment()
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  expect(queryAllByText('Available Jul 11, 2016 7:00pm')).toHaveLength(0)
})

it('renders the number of attempts with one attempt', async () => {
  const assignment = await mockAssignment({
    Assignment: {allowedAttempts: 1}
  })
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  expect(queryAllByText('1 Attempt')).toHaveLength(1)
})

it('renders the number of attempts with unlimited attempts', async () => {
  const assignment = await mockAssignment({
    Assignment: {allowedAttempts: null}
  })
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  expect(queryAllByText('Unlimited Attempts')).toHaveLength(1)
})

it('renders the number of attempts with multiple attempt', async () => {
  const assignment = await mockAssignment({
    Assignment: {allowedAttempts: 3}
  })
  const {queryAllByText} = render(<AssignmentDetails assignment={assignment} isSticky={false} />)
  expect(queryAllByText('3 Attempts')).toHaveLength(1)
})

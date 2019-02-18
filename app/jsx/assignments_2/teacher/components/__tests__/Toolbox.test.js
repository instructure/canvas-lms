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
import {render} from 'react-testing-library'
import {closest, mockAssignment, mockSubmission} from '../../test-utils'
import Toolbox from '../Toolbox'

it('renders basic information', () => {
  const assignment = mockAssignment({
    needsGradingCount: 1,
    submissions: {
      nodes: [mockSubmission({submittedAt: null}), mockSubmission()]
    }
  })

  const {queryByText, getByText, getByLabelText} = render(<Toolbox assignment={assignment} />)
  expect(getByLabelText('Published').getAttribute('checked')).toBe('')
  const sgLink = closest(getByText('1 to grade'), 'a')
  expect(sgLink).toBeTruthy()
  expect(sgLink.getAttribute('href')).toMatch(
    /\/courses\/course-lid\/gradebook\/speed_grader\?assignment_id=assignment-lid/
  )
  expect(closest(getByText('1 unsubmitted'), 'button')).toBeTruthy()
  expect(queryByText(/message students who/i)).toBeNull()
})

it('renders unpublished value checkbox', () => {
  const {getByLabelText} = render(<Toolbox assignment={mockAssignment({state: 'unpublished'})} />)
  expect(getByLabelText('Published').getAttribute('checked')).toBeFalsy()
})

it('should open speedgrader link in a new tab', () => {
  const assignment = mockAssignment()
  const {getByText} = render(<Toolbox assignment={assignment} />)
  const sgLink = closest(getByText('0 to grade'), 'a')
  expect(sgLink.getAttribute('target')).toEqual('_blank')
})

it('renders only the message students who button when the assignment does not have an online submission', () => {
  const assignment = mockAssignment({
    submissionTypes: ['on_paper']
  })
  const {queryByText, getByText} = render(<Toolbox assignment={assignment} />)
  expect(queryByText('unsubmitted', {exact: false})).toBeNull()
  expect(queryByText('to grade', {exact: false})).toBeNull()
  expect(getByText(/message students who/i)).toBeInTheDocument()
})

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {act, render, waitForElementToBeRemoved} from '@testing-library/react'
import moment from 'moment-timezone'
import {ignoreTodo} from '@canvas/k5/react/utils'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

import {MOCK_TODOS} from './mocks'
import Todo from '../Todo'

jest.mock('moment-timezone')
jest.mock('@canvas/k5/react/utils')

const timeZone = 'Europe/Dublin'

const defaultProps = {
  ...MOCK_TODOS[1],
  timeZone,
  openInNewTab: true,
}

beforeEach(() => {
  moment.mockImplementation(() => ({
    isSame: () => true,
    tz: () => null,
  }))
})

afterEach(() => {
  jest.resetAllMocks()
  // Clear flash alerts between tests
  destroyContainer()
})

describe('Todo', () => {
  it('renders the title as a link to the gradebook for the associated assignment', () => {
    const {getByRole} = render(<Todo {...defaultProps} />)
    const title = getByRole('link', {name: 'Grade Plant a plant'})
    expect(title).toBeInTheDocument()
    expect(title.getAttribute('href')).toMatch('/courses/5/gradebook/speed_grader?assignment_id=11')
  })

  it('renders the name of the associated course', () => {
    const {getByText} = render(<Todo {...defaultProps} />)
    expect(getByText('Horticulture')).toBeInTheDocument()
  })

  it('renders the number of points possible with correct pluralization', () => {
    const multiPoints = render(<Todo {...defaultProps} />)
    expect(multiPoints.getByText('15 points')).toBeInTheDocument()

    const props = {...defaultProps, assignment: {...defaultProps.assignment, points_possible: 1}}
    const singlePoint = render(<Todo {...props} />)
    expect(singlePoint.getByText('1 point')).toBeInTheDocument()
  })

  it('renders the due date without the year if it is in the current year', () => {
    moment.mockImplementation(() => ({
      isSame: () => true,
      tz: () => null,
    }))
    const currentYear = render(<Todo {...defaultProps} />)
    expect(currentYear.getByText('Jun 22 at 11:59pm')).toBeInTheDocument()
  })

  it('renders the due date with the year if it is a different year', () => {
    moment.mockImplementation(() => ({
      isSame: () => false,
      tz: () => null,
    }))
    const due_at = '2020-11-19T23:59:59Z'
    const props = {
      ...defaultProps,
      assignment: {...defaultProps.assignment, due_at, all_dates: [{base: true, due_at}]},
    }
    const currentYear = render(<Todo {...props} />)
    expect(currentYear.getByText('Nov 19, 2020 11:59pm')).toBeInTheDocument()
  })

  it('renders "No due date" if the assignment has no due date', () => {
    const due_at = null
    const props = {
      ...defaultProps,
      assignment: {...defaultProps.assignment, due_at: null, all_dates: [{base: true, due_at}]},
    }
    const currentYear = render(<Todo {...props} />)
    expect(currentYear.getByText('No Due Date')).toBeInTheDocument()
  })

  it('renders "multiple due dates" if the assignment has more than one due date', () => {
    moment.mockImplementation(() => ({
      isSame: () => true,
      tz: () => null,
    }))
    const base_due_at = '2021-07-02T23:59:59Z'
    const all_dates = [
      {
        base: true,
        due_at: base_due_at,
      },
      {
        base: false,
        due_at: '2021-07-09T23:59:59Z',
      },
    ]
    const props = {
      ...defaultProps,
      assignment: {...defaultProps.assignment, due_at: base_due_at, all_dates},
    }
    const {getByText} = render(<Todo {...props} />)
    expect(getByText('Jul 2 at 11:59pm')).toBeInTheDocument()
    expect(getByText('(Multiple Due Dates)')).toBeInTheDocument()
  })

  it('displays a badge with the number of submissions that need grading with correct pluralization', () => {
    const multiSubmissions = render(<Todo {...defaultProps} />)
    expect(multiSubmissions.getByText('3 submissions need grading')).toBeInTheDocument()

    const singleSubmission = render(<Todo {...defaultProps} needs_grading_count={1} />)
    expect(singleSubmission.getByText('1 submission needs grading')).toBeInTheDocument()
  })

  it('does not render anything for non-assignment todos', () => {
    const {queryByText} = render(<Todo {...defaultProps} assignment={undefined} />)
    expect(queryByText('Plant some plants')).not.toBeInTheDocument()
  })

  it('displays a button that ignores the associated todo and removes it from the rendered list', async () => {
    ignoreTodo.mockResolvedValue({ignored: true})

    const {getByRole, queryByText} = render(<Todo {...defaultProps} />)
    const ignoreButton = getByRole('button', {name: 'Ignore Plant a plant until new submission'})
    expect(ignoreButton).toBeInTheDocument()

    act(() => ignoreButton.click())

    return waitForElementToBeRemoved(() => queryByText('Grade Plant a plant'))
  })

  it('shows a flash error if ignoring a todo fails', async () => {
    ignoreTodo.mockRejectedValue(new Error('Uh oh'))

    const {findAllByText, getByRole} = render(<Todo {...defaultProps} />)
    const ignoreButton = getByRole('button', {name: 'Ignore Plant a plant until new submission'})

    act(() => ignoreButton.click())

    expect((await findAllByText('Failed to ignore assignment'))[0]).toBeInTheDocument()
  })

  it('adds target attribute to link if openInNewTab is true', () => {
    const {getByRole} = render(<Todo {...defaultProps} />)
    const link = getByRole('link', {name: 'Grade Plant a plant'})
    expect(link.getAttribute('target')).toBe('_blank')
  })

  it('does not add target attribute to link if openInNewTab is false', () => {
    const {getByRole} = render(<Todo {...defaultProps} openInNewTab={false} />)
    const link = getByRole('link', {name: 'Grade Plant a plant'})
    expect(link.getAttribute('target')).toBeNull()
  })
})

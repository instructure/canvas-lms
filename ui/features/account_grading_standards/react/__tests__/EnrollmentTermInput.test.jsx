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
import EnrollmentTermInput from '../EnrollmentTermInput'
import '@testing-library/jest-dom/extend-expect'

const defaultProps = {
  enrollmentTerms: [
    {
      id: '1',
      name: 'Fall 2009 - Art',
      startAt: new Date('2009-06-03T02:57:42.000Z'),
      endAt: new Date('2009-12-03T02:57:53.000Z'),
      createdAt: new Date('2009-05-27T16:51:41.000Z'),
      workflowState: 'active',
      gradingPeriodGroupId: '65',
      sisTermId: null,
      displayName: 'Fall 2009 - Art',
    },
    {
      id: '2',
      name: null,
      startAt: null,
      endAt: new Date('2013-12-03T02:57:53.000Z'),
      createdAt: new Date('2015-10-27T16:51:41.000Z'),
      workflowState: 'active',
      gradingPeriodGroupId: '62',
      sisTermId: null,
      displayName: 'Term created Oct 27, 2015',
    },
    {
      id: '5',
      name: null,
      startAt: new Date('2012-06-06T20:09:32.000Z'),
      endAt: null,
      createdAt: new Date('2012-06-03T20:09:32.000Z'),
      workflowState: 'active',
      gradingPeriodGroupId: '64',
      sisTermId: null,
      displayName: 'Term starting Jun 6, 2016',
    },
  ],
  selectedIDs: ['2'],
  setSelectedEnrollmentTermIDs: jest.fn(),
}

const renderComponent = (props = {}) => {
  return render(<EnrollmentTermInput {...{...defaultProps, ...props}} />)
}

describe('EnrollmentTermInput', () => {
  beforeEach(() => {
    const flashMessages = document.createElement('div')
    flashMessages.id = 'flash-messages'
    flashMessages.setAttribute('role', 'alert')
    document.body.appendChild(flashMessages)

    const flashScreenreaderHolder = document.createElement('div')
    flashScreenreaderHolder.id = 'flash_screenreader_holder'
    flashScreenreaderHolder.setAttribute('role', 'alert')
    document.body.appendChild(flashScreenreaderHolder)
  })

  afterEach(() => {
    const flashMessages = document.getElementById('flash-messages')
    if (flashMessages) {
      flashMessages.remove()
    }

    const flashScreenreaderHolder = document.getElementById('flash_screenreader_holder')
    if (flashScreenreaderHolder) {
      document.body.removeChild(flashScreenreaderHolder)
    }
  })

  it('displays "No unassigned terms" if there are no selectable terms', async () => {
    const user = userEvent.setup()
    renderComponent({enrollmentTerms: [], selectedIDs: []})
    await user.click(screen.getByTestId('enrollment-term-select'))
    expect(screen.getByText('No unassigned terms')).toBeInTheDocument()
  })

  it('displays selected enrollment term with correct display name', () => {
    renderComponent()
    expect(screen.getByTestId('enrollment-term-select')).toBeInTheDocument()
    expect(screen.getByText('Term created Oct 27, 2015')).toBeInTheDocument()
  })

  it('displays selectable terms with correct display names', async () => {
    const user = userEvent.setup()
    renderComponent({
      enrollmentTerms: defaultProps.enrollmentTerms.filter(term => term.id !== '2'),
      selectedIDs: [],
    })
    await user.click(screen.getByTestId('enrollment-term-select'))
    expect(await screen.findByTestId('enrollment-term-option-1')).toBeInTheDocument()
    expect(await screen.findByTestId('enrollment-term-option-5')).toBeInTheDocument()
  })

  it('allows removing selected terms', async () => {
    const user = userEvent.setup()
    const setSelectedEnrollmentTermIDs = jest.fn()
    renderComponent({setSelectedEnrollmentTermIDs})
    const removeButton = screen.getByTestId('enrollment-term-tag-2')
    await user.click(removeButton)

    expect(setSelectedEnrollmentTermIDs).toHaveBeenCalledWith([])
  })

  it('allows selecting a term from the dropdown', async () => {
    const user = userEvent.setup()
    const setSelectedEnrollmentTermIDs = jest.fn()
    renderComponent({setSelectedEnrollmentTermIDs})
    await user.click(screen.getByTestId('enrollment-term-select'))
    await user.click(await screen.findByTestId('enrollment-term-option-5'))
    expect(setSelectedEnrollmentTermIDs).toHaveBeenCalledWith(['2', '5'])
  })

  it('groups terms by their status', async () => {
    const user = userEvent.setup()
    const now = new Date()
    const terms = [
      {
        id: '1',
        name: 'Active Term',
        startAt: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        endAt: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        workflowState: 'active',
        displayName: 'Active Term',
      },
      {
        id: '2',
        name: 'Future Term',
        startAt: new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000), // 60 days from now
        endAt: new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000), // 90 days from now
        workflowState: 'active',
        displayName: 'Future Term',
      },
      {
        id: '3',
        name: 'Past Term',
        startAt: new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000), // 90 days ago
        endAt: new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000), // 60 days ago
        workflowState: 'active',
        displayName: 'Past Term',
      },
    ]

    renderComponent({enrollmentTerms: terms, selectedIDs: []})
    await user.click(screen.getByTestId('enrollment-term-select'))

    expect(screen.getByText('Active')).toBeInTheDocument()
    expect(screen.getByText('Future')).toBeInTheDocument()
    expect(screen.getByText('Past')).toBeInTheDocument()

    expect(screen.getByText('Active Term')).toBeInTheDocument()
    expect(screen.getByText('Future Term')).toBeInTheDocument()
    expect(screen.getByText('Past Term')).toBeInTheDocument()
  })
})

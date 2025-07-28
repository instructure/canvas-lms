/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import EnrollmentTermsDropdown from '../EnrollmentTermsDropdown'

const mockTerms = [
  {
    id: '18',
    name: 'Fall 2013 - Art',
    startAt: new Date('2013-08-03T02:57:42.000Z'),
    endAt: new Date('2013-11-03T02:57:53.000Z'),
    createdAt: new Date('2013-07-27T16:51:41.000Z'),
    gradingPeriodGroupId: '3',
    displayName: 'Fall 2013 - Art',
  },
  {
    id: '21',
    name: 'Winter 2013 - Art',
    startAt: new Date('2013-12-03T02:57:42.000Z'),
    endAt: new Date('2014-01-21T02:57:53.000Z'),
    createdAt: new Date('2013-08-27T16:51:41.000Z'),
    gradingPeriodGroupId: '3',
    displayName: 'Winter 2013 - Art',
  },
  {
    id: '2',
    name: null,
    startAt: null,
    endAt: new Date('2013-10-21T02:57:53.000Z'),
    createdAt: new Date('2013-08-22T16:51:41.000Z'),
    gradingPeriodGroupId: '2',
    displayName: 'Term starting Sep 3, 2013',
  },
  {
    id: '7',
    name: null,
    startAt: null,
    endAt: null,
    createdAt: new Date('2013-08-23T16:51:41.000Z'),
    gradingPeriodGroupId: '2',
    displayName: 'Term created Aug 23, 2013',
  },
]

describe('EnrollmentTermsDropdown', () => {
  const renderDropdown = (props = {}) => {
    const defaultProps = {
      terms: mockTerms,
      changeSelectedEnrollmentTerm: jest.fn(),
    }
    return render(<EnrollmentTermsDropdown {...defaultProps} {...props} />)
  }

  it('renders the dropdown with all terms option', () => {
    renderDropdown()
    const dropdown = screen.getByRole('combobox', {name: 'Enrollment Term', hidden: true})
    const options = screen.getAllByRole('option', {hidden: true})

    expect(dropdown).toBeInTheDocument()
    expect(options[0]).toHaveTextContent('All Terms')
    expect(options).toHaveLength(mockTerms.length + 1)
  })

  it('sorts terms by start date in descending order', () => {
    renderDropdown()
    const options = screen.getAllByRole('option', {hidden: true})

    // Skip "All Terms" option at index 0
    expect(options[1]).toHaveTextContent('Winter 2013 - Art')
    expect(options[2]).toHaveTextContent('Fall 2013 - Art')
  })

  it('groups undated terms after dated terms and sorts by creation date', () => {
    renderDropdown()
    const options = screen.getAllByRole('option', {hidden: true})

    // Verify undated terms appear after dated terms, sorted by creation date in descending order
    expect(options[options.length - 2]).toHaveTextContent('Term created Aug 23, 2013')
    expect(options[options.length - 1]).toHaveTextContent('Term starting Sep 3, 2013')
  })

  it('calls changeSelectedEnrollmentTerm when selection changes', async () => {
    const handleChange = jest.fn()
    renderDropdown({changeSelectedEnrollmentTerm: handleChange})

    const dropdown = screen.getByRole('combobox', {name: 'Enrollment Term', hidden: true})
    await userEvent.selectOptions(dropdown, '21')

    expect(handleChange).toHaveBeenCalled()
  })
})

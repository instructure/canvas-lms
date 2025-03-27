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
import {render} from '@testing-library/react'
import CoursePeople from '../CoursePeople'
import useCoursePeopleQuery from '../hooks/useCoursePeopleQuery'
import useSearch from '../hooks/useSearch'
import {mockUser, mockEnrollment} from '../../graphql/Mocks'
import {
  INACTIVE_ENROLLMENT,
  PENDING_ENROLLMENT
} from '../../util/constants'
import {User} from '../../types'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('../hooks/useCoursePeopleQuery')
jest.mock('../hooks/useSearch')
jest.mock('../components/PageHeader/CoursePeopleHeader', () => () => <div data-testid="page-header" />)
jest.mock('../components/RosterTable/RosterTable', () => ({users}: {users: User[]}) => (
  <div data-testid="roster-table">RosterTable: {users.map(user => user._id).join(',')}</div>
))
jest.mock('../components/SearchPeople/PeopleSearchBar', () => ({searchTerm}: {searchTerm: string}) => (
  <div data-testid="search-bar">SearchBar: {searchTerm}</div>
))
jest.mock('../components/FilterPeople/PeopleFilter', () => ({onOptionSelect}: {onOptionSelect: (id: string) => void}) => (
  <div
    data-testid="people-filter"
    role="button"
    tabIndex={0}
    onClick={() => onOptionSelect('test-id')}
    onKeyDown={(e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        onOptionSelect('test-id')
      }
    }}
  >
    PeopleFilter
  </div>
))
jest.mock('../components/SearchPeople/NoPeopleFound', () => () => <div data-testid="no-people-found" />)

const mockUsers = [
  mockUser({
    userId: '1',
    userName: 'Student One'
  }),
  mockUser({
    userId: '2',
    userName: 'Student Two',
    firstEnrollment: mockEnrollment({enrollmentState: INACTIVE_ENROLLMENT})
  }),
  mockUser({
    userId: '3',
    userName: 'Student Three',
    firstEnrollment: mockEnrollment({enrollmentState: PENDING_ENROLLMENT})
  }),
]

describe('CoursePeople', () => {
  beforeEach(() => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: mockUsers,
      isLoading: false,
      error: null
    });
    (useSearch as jest.Mock).mockImplementation(() => ({
      search: 'test user',
      debouncedSearch: 'test user',
      onChangeHandler: jest.fn(),
      onClearHandler: jest.fn(),
    }));
    (showFlashAlert as jest.Mock).mockClear()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders all required components', () => {
    const {getByTestId} = render(<CoursePeople />)
    expect(getByTestId('page-header')).toBeInTheDocument()
    expect(getByTestId('search-bar')).toBeInTheDocument()
    expect(getByTestId('people-filter')).toBeInTheDocument()
    expect(getByTestId('roster-table')).toBeInTheDocument()
  })

  it('renders NoPeopleFound component if no people', () => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: [],
      isLoading: false,
      error: null
    })
    const {getByTestId} = render(<CoursePeople />)
    expect(getByTestId('no-people-found')).toBeInTheDocument()
  })

  it('passes users to RosterTable', () => {
    const userIds = mockUsers.map(user => user._id).join(',')
    const {getByTestId} = render(<CoursePeople />)
    expect(getByTestId('roster-table')).toHaveTextContent(`RosterTable: ${userIds}`)
  })

  it('passes search term to PeopleSearchBar', () => {
    const {getByTestId} = render(<CoursePeople />)
    expect(getByTestId('search-bar')).toHaveTextContent(`SearchBar: test user`)
  })

  it('passes handler for selected option to PeopleFilter', () => {
    const {getByTestId} = render(<CoursePeople />)
    const filter = getByTestId('people-filter')
    expect(filter).toBeInTheDocument()
    filter.click()
    expect(useCoursePeopleQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        optionId: 'test-id'
      })
    )
  })

  it('passes search term to query hook', () => {
    render(<CoursePeople />)
    expect(useCoursePeopleQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        searchTerm: 'test user'
      })
    )
  })

  it('displays loading state', () => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: null,
      isLoading: true,
      error: null
    })
    const {getByText} = render(<CoursePeople />)
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('displays flash error message if query fails', () => {
    (useCoursePeopleQuery as jest.Mock).mockReturnValue({
      data: null,
      isLoading: false,
      error: new Error()
    })
    render(<CoursePeople />)
    expect(showFlashAlert).toHaveBeenCalledWith(expect.objectContaining({
      message: 'An error occurred while loading people.',
      type: 'error'
    }))
  })
})

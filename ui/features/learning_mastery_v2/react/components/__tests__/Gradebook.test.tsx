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
import {render} from '@testing-library/react'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {Gradebook, GradebookProps} from '../Gradebook'
import {SortOrder, SortBy} from '../../utils/constants'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../__fixtures__/rollups'

// Helper to render with MockedQueryClientProvider
const renderWithQueryClient = (ui: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
}

describe('Gradebook', () => {
  const defaultProps = (props = {}): GradebookProps => {
    return {
      students: MOCK_STUDENTS,
      outcomes: MOCK_OUTCOMES,
      rollups: [
        {
          studentId: '1',
          outcomeRollups: [],
        },
        {
          studentId: '2',
          outcomeRollups: [],
        },
      ],
      courseId: '100',
      setCurrentPage: jest.fn(),
      sorting: {
        sortOrder: SortOrder.ASC,
        setSortOrder: jest.fn(),
        sortBy: SortBy.SortableName,
        setSortBy: jest.fn(),
        sortOutcomeId: null,
        setSortOutcomeId: jest.fn(),
      },
      onChangeNameDisplayFormat: jest.fn(),
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.GRADEBOOK_OPTIONS = {ACCOUNT_LEVEL_MASTERY_SCALES: true}
  })

  it('renders each student', () => {
    const props = defaultProps()
    const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
    props.students.forEach(student => {
      expect(getByText(student.display_name)).toBeInTheDocument()
    })
  })

  it('renders each outcome', () => {
    const props = defaultProps()
    const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
    props.outcomes.forEach(outcome => {
      expect(getByText(outcome.title)).toBeInTheDocument()
    })
  })

  describe('pagination', () => {
    it('does not render pagination controls when there is only one page', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 1}})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).not.toBeInTheDocument()
    })

    it('does not render pagination controls when pagination is not provided', () => {
      const props = defaultProps({pagination: undefined})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).not.toBeInTheDocument()
    })

    it('renders pagination controls when there are multiple pages', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 2}})
      const {queryByTestId} = renderWithQueryClient(<Gradebook {...props} />)
      expect(queryByTestId('gradebook-pagination')).toBeInTheDocument()
    })

    it('calls setCurrentPage when page number button is clicked', () => {
      const props = defaultProps({pagination: {currentPage: 1, perPage: 10, totalPages: 3}})
      const {getByText} = renderWithQueryClient(<Gradebook {...props} />)
      const page2Button = getByText('2')
      page2Button.click()
      expect(props.setCurrentPage).toHaveBeenCalledWith(2)
    })
  })
})

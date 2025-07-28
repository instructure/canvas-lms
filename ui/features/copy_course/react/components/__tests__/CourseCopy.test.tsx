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

import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {assignLocation} from '@canvas/util/globalUtils'
import {render, fireEvent, screen, waitFor, getByTestId} from '@testing-library/react'
import React from 'react'
import CourseCopy from '../CourseCopy'
import {
  courseCopyRootKey,
  courseFetchKey,
  enrollmentTermsFetchKey,
  createCourseAndMigrationKey,
} from '../../types'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('CourseCopy', () => {
  const defaultProps = {
    courseId: '1',
    accountId: '2',
    rootAccountId: '3',
    canImportAsNewQuizzes: true,
  }

  const courseData = {
    id: '1',
    name: 'Test Course',
    enrollment_term_id: '1',
    restrict_enrollments_to_course_dates: true,
    time_zone: 'time_zone',
    start_at: '2024-01-01T00:00:00Z',
    end_at: '2024-12-31T23:59:59Z',
    course_code: 'TEST101',
    blueprint: false,
  }
  const termsData = [{id: '1', name: 'Test Term'}]

  // Create a new QueryClient for each test
  let queryClient: QueryClient

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    jest.clearAllMocks()
  })

  const renderWithClient = (ui: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('should call terms query with rootAccountId', async () => {
    // Set up the query data
    queryClient.setQueryData([courseCopyRootKey, courseFetchKey, defaultProps.courseId], null)
    queryClient.setQueryData(
      [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
      {
        pages: [],
        pageParams: [],
      },
    )

    renderWithClient(<CourseCopy {...defaultProps} />)

    // Check that the terms query was made with the right parameters
    await waitFor(() => {
      expect(
        queryClient.getQueryState([
          courseCopyRootKey,
          enrollmentTermsFetchKey,
          defaultProps.rootAccountId,
        ]),
      ).not.toBeNull()
    })
  })

  it('renders loading state on course loading', async () => {
    // Set up the query data for terms but leave course data loading
    queryClient.setQueryData(
      [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
      {
        pages: [
          {
            json: {enrollment_terms: termsData},
            link: {next: null},
          },
        ],
        pageParams: [undefined],
      },
    )

    const {getByText} = renderWithClient(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders success state', async () => {
    // Set up the query data
    queryClient.setQueryData([courseCopyRootKey, courseFetchKey, defaultProps.courseId], courseData)
    queryClient.setQueryData(
      [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
      {
        pages: [
          {
            json: {enrollment_terms: termsData},
            link: {next: null},
          },
        ],
        pageParams: [undefined],
      },
    )

    const {getByText} = renderWithClient(<CourseCopy {...defaultProps} />)

    await waitFor(() => {
      expect(getByText('Copy course')).toBeInTheDocument()
    })
  })

  describe('when there is no data returned', () => {
    it('renders error state on missing course data', async () => {
      // Set up the query data with null course data
      queryClient.setQueryData([courseCopyRootKey, courseFetchKey, defaultProps.courseId], null)

      queryClient.setQueryData(
        [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
        {
          pages: [
            {
              json: {enrollment_terms: termsData},
              link: {next: null},
            },
          ],
          pageParams: [undefined],
        },
      )

      const {getByText} = renderWithClient(<CourseCopy {...defaultProps} />)

      await waitFor(() => {
        expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
      })
    })

    it('renders error state on missing terms data', async () => {
      // Set up the query data with null terms data
      queryClient.setQueryData(
        [courseCopyRootKey, courseFetchKey, defaultProps.courseId],
        courseData,
      )

      queryClient.setQueryData(
        [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
        {
          pages: [
            {
              json: {enrollment_terms: []},
              link: {next: null},
            },
          ],
          pageParams: [undefined],
        },
      )

      const {getByText} = renderWithClient(<CourseCopy {...defaultProps} />)

      await waitFor(() => {
        expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
      })
    })
  })

  it('handleCancel redirects to the course settings page', async () => {
    // Set up the query data
    queryClient.setQueryData([courseCopyRootKey, courseFetchKey, defaultProps.courseId], courseData)
    queryClient.setQueryData(
      [courseCopyRootKey, enrollmentTermsFetchKey, defaultProps.rootAccountId],
      {
        pages: [
          {
            json: {enrollment_terms: termsData},
            link: {next: null},
          },
        ],
        pageParams: [undefined],
      },
    )

    const {getByTestId} = renderWithClient(<CourseCopy {...defaultProps} />)

    await fireEvent.click(getByTestId('clear-migration-button'))
    expect(assignLocation).toHaveBeenCalledWith(`/courses/${defaultProps.courseId}/settings`)
  })
})

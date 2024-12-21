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

import {useMutation, useQuery} from '@canvas/query'
import {assignLocation} from '@canvas/util/globalUtils'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {useTermsQuery} from '../../queries/termsQuery'
import CourseCopy from '../CourseCopy'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

jest.mock('@canvas/query')
jest.mock('../../queries/termsQuery')

describe('CourseCopy', () => {
  const defaultProps = {
    courseId: '1',
    accountId: '1',
    canImportAsNewQuizzes: true,
  }

  const courseData = {id: '1', name: 'Test Course', enrollment_term_id: 1}
  const termsData = [{id: '1', name: 'Test Term'}]

  const mockUseQuery = useQuery as jest.Mock
  const mockUseMutation = useMutation as jest.Mock
  const mockUseTermsQuery = useTermsQuery as jest.Mock

  afterEach(() => {
    mockUseMutation.mockReset()
  })

  it('renders loading state on course loading', () => {
    mockUseQuery.mockReturnValue({isLoading: true})
    mockUseTermsQuery.mockReturnValue({isLoading: false, isError: false, hasNextPage: false})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders loading state on terms loading', () => {
    mockUseQuery.mockReturnValue({isLoading: false})
    mockUseTermsQuery.mockReturnValue({isLoading: true, isError: false, hasNextPage: false})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders loading state on terms has next page', () => {
    mockUseQuery.mockReturnValue({isLoading: false})
    mockUseTermsQuery.mockReturnValue({isLoading: false, isError: false, hasNextPage: true})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders success state', () => {
    mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: courseData})
    mockUseTermsQuery.mockReturnValue({
      isLoading: false,
      isError: false,
      data: termsData,
      hasNextPage: false,
    })
    mockUseMutation.mockReturnValue({isLoading: false, isSuccess: false})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Copy course')).toBeInTheDocument()
  })

  describe('when there is an error', () => {
    it('renders error state on course loading error', () => {
      mockUseQuery.mockReturnValue({isLoading: false, isError: true, data: null})
      mockUseTermsQuery.mockReturnValue({
        isLoading: false,
        isError: false,
        data: null,
        hasNextPage: false,
      })

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error state on terms loading error', () => {
      mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: null})
      mockUseTermsQuery.mockReturnValue({
        isLoading: false,
        isError: true,
        data: null,
        hasNextPage: false,
      })

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error state on terms error but has next page', () => {
      mockUseQuery.mockReturnValue({isLoading: false})
      mockUseTermsQuery.mockReturnValue({
        isLoading: false,
        isError: true,
        data: null,
        hasNextPage: true,
      })

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('when there is no data returned', () => {
    it('renders error state on missing course data', () => {
      mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: null})
      mockUseTermsQuery.mockReturnValue({
        isLoading: false,
        isError: false,
        data: {},
        hasNextPage: false,
      })

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error state on missing terms data', () => {
      mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: {}})
      mockUseTermsQuery.mockReturnValue({
        isLoading: false,
        isError: false,
        data: null,
        hasNextPage: false,
      })

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('handleCancel redirects to the course settings page', () => {
    mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: courseData})
    mockUseTermsQuery.mockReturnValue({
      isLoading: false,
      isError: false,
      data: termsData,
      hasNextPage: false,
    })
    mockUseMutation.mockReturnValue({isLoading: false, isSuccess: false})

    const {getByRole} = render(<CourseCopy {...defaultProps} />)

    fireEvent.click(getByRole('button', {name: 'Cancel'}))
    expect(assignLocation).toHaveBeenCalledWith(`/courses/${defaultProps.courseId}/settings`)
  })

  it('handleSubmit calls mutate', () => {
    const mockMutate = jest.fn()
    mockUseQuery.mockReturnValue({isLoading: false, isError: false, data: courseData})
    mockUseTermsQuery.mockReturnValue({
      isLoading: false,
      isError: false,
      data: termsData,
      hasNextPage: false,
    })
    mockUseMutation.mockReturnValue({isLoading: false, isSuccess: false, mutate: mockMutate})

    const {getByRole} = render(<CourseCopy {...defaultProps} />)

    fireEvent.click(getByRole('button', {name: 'Create course'}))

    expect(mockMutate).toHaveBeenCalledWith({
      accountId: defaultProps.accountId,
      courseId: defaultProps.courseId,
      formData: {
        courseName: courseData.name,
        courseCode: '',
        newCourseStartDate: null,
        newCourseEndDate: null,
        selectedTerm: termsData[0],
        adjust_dates: {enabled: false, operation: 'shift_dates'},
        date_shift_options: {
          old_start_date: '',
          new_start_date: '',
          old_end_date: '',
          new_end_date: '',
          day_substitutions: [],
        },
        selective_import: false,
        settings: {
          import_quizzes_next: false,
        },
        errored: false,
      },
    })
  })
})

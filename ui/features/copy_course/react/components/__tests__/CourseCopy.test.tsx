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
import {fireEvent, render} from '@testing-library/react'
import {useQuery, useMutation} from '@canvas/query'
import CourseCopy from '../CourseCopy'

jest.mock('@canvas/query')

describe('CourseCopy', () => {
  const defaultProps = {
    courseId: '1',
    accountId: '1',
    canImportAsNewQuizzes: true,
  }

  const courseData = {id: '1', name: 'Test Course'}
  const termsData = [{id: '1', name: 'Test Term'}]

  const mockUseQuery = useQuery as jest.Mock
  const mockUseMutation = useMutation as jest.Mock

  afterEach(() => {
    mockUseMutation.mockReset()
  })

  it('renders loading state', () => {
    mockUseQuery.mockReturnValue({isLoading: true})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders success state', () => {
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: courseData})
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: termsData})
    mockUseMutation.mockReturnValue({isLoading: false, isSuccess: false})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Copy course')).toBeInTheDocument()
  })

  describe('when there is an error', () => {
    it('renders error state on course loading error', () => {
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: true, data: null})
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: null})

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error state on terms loading error', () => {
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: null})
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: true, data: null})

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('when there is no data returned', () => {
    it('renders error state on missing course data', () => {
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: null})
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: {}})

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error state on missing terms data', () => {
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: {}})
      mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: null})

      const {getByText} = render(<CourseCopy {...defaultProps} />)

      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('handleCancel redirects to the course settings page', () => {
    // @ts-ignore
    delete window.location
    window.location = {href: ''} as Location
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: courseData})
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: termsData})
    mockUseMutation.mockReturnValue({isLoading: false, isSuccess: false})

    const {getByRole} = render(<CourseCopy {...defaultProps} />)

    fireEvent.click(getByRole('button', {name: 'Clear'}))
    expect(window.location.href).toBe(`/courses/${defaultProps.courseId}/settings`)
  })

  it('handleSubmit calls mutate', () => {
    const mockMutate = jest.fn()
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: courseData})
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: termsData})
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

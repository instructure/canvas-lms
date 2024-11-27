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
import {render} from '@testing-library/react'
import {useQuery} from '@canvas/query'
import CourseCopy from '../CourseCopy'

jest.mock('@canvas/query')

const mockUseQuery = useQuery as jest.Mock

describe('CourseCopy', () => {
  const defaultProps = {
    courseId: '1',
    accountId: '1',
    canImportAsNewQuizzes: true,
  }

  it('renders loading state', () => {
    mockUseQuery.mockReturnValue({isLoading: true})

    const {getByText} = render(<CourseCopy {...defaultProps} />)

    expect(getByText('Course copy page is loading')).toBeInTheDocument()
  })

  it('renders success state', () => {
    const courseData = {id: '1', name: 'Test Course'}
    const termsData = [{id: '1', name: 'Test Term'}]

    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: courseData})
    mockUseQuery.mockReturnValueOnce({isLoading: false, isError: false, data: termsData})

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
})

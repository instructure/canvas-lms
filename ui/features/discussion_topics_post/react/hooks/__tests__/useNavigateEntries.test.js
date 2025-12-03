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

import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import useNavigateEntries from '../useNavigateEntries'
import * as useSpeedGraderModule from '../useSpeedGrader'
import * as useStudentEntriesModule from '../useStudentEntries'

jest.mock('../useSpeedGrader')
jest.mock('../useStudentEntries')

describe('useNavigateEntries', () => {
  const mockSetHighlightEntryId = jest.fn()
  const mockSetPageNumber = jest.fn()
  const mockSetExpandedThreads = jest.fn()
  const mockSetFocusSelector = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()

    // Mock window.location with proper URL object
    const url = new URL('http://localhost?student_id=123')
    delete window.location
    window.location = url

    // Mock URL constructor to return our test URL
    global.URL = jest.fn(() => url)

    // Default mock implementations
    jest.spyOn(useSpeedGraderModule, 'default').mockReturnValue({
      isInSpeedGrader: true,
      handleCommentKeyPress: jest.fn(),
      handleGradeKeyPress: jest.fn(),
    })
  })

  const defaultProps = {
    highlightEntryId: '456',
    setHighlightEntryId: mockSetHighlightEntryId,
    setPageNumber: mockSetPageNumber,
    expandedThreads: [],
    setExpandedThreads: mockSetExpandedThreads,
    setFocusSelector: mockSetFocusSelector,
    discussionID: '789',
    perPage: 20,
    sort: 'asc',
  }

  const mockStudentEntriesQuery = (isLoading = false, entries = []) => {
    jest.spyOn(useStudentEntriesModule, 'useStudentEntries').mockReturnValue({
      data: {
        pages: entries.length > 0 ? [{entries}] : [],
      },
      isLoading,
      refetch: jest.fn(),
    })
  }

  describe('auto-navigation behavior', () => {
    it('should NOT auto-navigate when highlightEntryId is null', async () => {
      const entries = [
        {_id: '100', rootEntryPageNumber: 1},
        {_id: '200', rootEntryPageNumber: 1},
      ]
      mockStudentEntriesQuery(false, entries)

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: null,
        }),
      )

      await waitFor(() => {
        expect(mockSetHighlightEntryId).not.toHaveBeenCalled()
      })
    })

    it('should NOT auto-navigate when highlightEntryId is undefined', async () => {
      const entries = [
        {_id: '100', rootEntryPageNumber: 1},
        {_id: '200', rootEntryPageNumber: 1},
      ]
      mockStudentEntriesQuery(false, entries)

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: undefined,
        }),
      )

      await waitFor(() => {
        expect(mockSetHighlightEntryId).not.toHaveBeenCalled()
      })
    })

    it('should auto-navigate to first entry when highlightEntryId is not found in entries', async () => {
      const entries = [
        {_id: '100', rootEntryPageNumber: 1, rootEntryId: null},
        {_id: '200', rootEntryPageNumber: 1, rootEntryId: null},
      ]
      mockStudentEntriesQuery(false, entries)

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: '999', // ID not in the list
        }),
      )

      await waitFor(
        () => {
          expect(mockSetHighlightEntryId).toHaveBeenCalledWith('100')
          expect(mockSetPageNumber).toHaveBeenCalledWith(1)
        },
        {timeout: 3000},
      )
    })

    it('should NOT auto-navigate when highlightEntryId is found in entries', async () => {
      const entries = [
        {_id: '100', rootEntryPageNumber: 1, rootEntryId: null},
        {_id: '200', rootEntryPageNumber: 1, rootEntryId: null},
      ]
      mockStudentEntriesQuery(false, entries)

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: '100', // ID that exists in the list
        }),
      )

      await waitFor(() => {
        expect(mockSetHighlightEntryId).not.toHaveBeenCalled()
      })
    })

    it('should NOT auto-navigate when not in SpeedGrader', async () => {
      jest.spyOn(useSpeedGraderModule, 'default').mockReturnValue({
        isInSpeedGrader: false,
        handleCommentKeyPress: jest.fn(),
        handleGradeKeyPress: jest.fn(),
      })

      const entries = [
        {_id: '100', rootEntryPageNumber: 1},
        {_id: '200', rootEntryPageNumber: 1},
      ]
      mockStudentEntriesQuery(false, entries)

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: '999',
        }),
      )

      await waitFor(() => {
        expect(mockSetHighlightEntryId).not.toHaveBeenCalled()
      })
    })

    it('should NOT auto-navigate while entries are loading', async () => {
      const entries = [
        {_id: '100', rootEntryPageNumber: 1},
        {_id: '200', rootEntryPageNumber: 1},
      ]
      mockStudentEntriesQuery(true, entries) // isLoading = true

      renderHook(() =>
        useNavigateEntries({
          ...defaultProps,
          highlightEntryId: '999',
        }),
      )

      await waitFor(() => {
        expect(mockSetHighlightEntryId).not.toHaveBeenCalled()
      })
    })
  })
})

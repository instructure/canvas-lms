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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import axios from '@canvas/axios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useCSVExport, {EXPORT_COMPLETE, EXPORT_FAILED, EXPORT_NOT_STARTED} from '../useCSVExport'

jest.useFakeTimers()

jest.mock('@canvas/axios', () => ({
  get: jest.fn(),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('useCSVExport', () => {
  let exportMock
  const mockedExport =
    'Student name, Student ID, Student SIS ID, Outcome 1 result, Outcome 1 mastery points\n' +
    'test student, 1, student_1, 2.5, 3\n' +
    'other student, 2, student_2, 3.3, 3'

  const defaultProps = (props = {}) => {
    return {
      courseId: '1',
      gradebookFilters: [],
      ...props,
    }
  }

  const forceURLFail = () => {
    exportMock = axios.get.mockRejectedValue({})
  }

  beforeEach(() => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        mockedExport,
      },
    })
    exportMock = axios.get.mockResolvedValue(promise)
  })

  describe('useCSVExport hook', () => {
    it('returns the response when an export is requested', async () => {
      const {result} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook, exportState, exportData} = result.current

      // Validate initial state of hook
      expect(exportState).toEqual(EXPORT_NOT_STARTED)
      expect(exportData).toStrictEqual([])

      // Request the Export
      act(() => exportGradebook())
      await act(async () => jest.runAllTimers())

      // Validate end state of hook
      expect(result.current.exportState).toEqual(EXPORT_COMPLETE)
      expect(result.current.exportData).toStrictEqual({
        mockedExport,
      })
    })

    it('calls the /rollups.csv URL with the right parameters', async () => {
      const {result} = renderHook(() =>
        useCSVExport(
          defaultProps({gradebookFilters: ['inactive_enrollments', 'missing_user_rollups']})
        )
      )
      const params = {
        params: {
          exclude: ['inactive_enrollments', 'missing_user_rollups'],
        },
      }
      const {exportGradebook} = result.current

      act(() => exportGradebook())
      await act(async () => jest.runAllTimers())

      expect(exportMock).toHaveBeenCalledWith('/courses/1/outcome_rollups.csv', params)
    })

    it('export state is failed when export fails', async () => {
      const {result} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook} = result.current

      forceURLFail()
      act(() => exportGradebook())
      await act(async () => jest.runAllTimers())

      expect(axios.get).toHaveBeenCalled()
      expect(result.current.exportState).toEqual(EXPORT_FAILED)
      expect(result.current.exportData).toStrictEqual([])
    })

    it('shows flash alert when export fails', async () => {
      const {result} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook} = result.current

      forceURLFail()
      act(() => exportGradebook())
      await act(async () => jest.runAllTimers())

      expect(axios.get).toHaveBeenCalled()
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Error exporting gradebook',
        type: 'error',
      })
    })
  })
})

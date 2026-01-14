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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useCSVExport, {EXPORT_COMPLETE, EXPORT_FAILED, EXPORT_NOT_STARTED} from '../useCSVExport'

const server = setupServer()

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(() => vi.fn(() => {})),
}))

describe('useCSVExport', () => {
  const mockedExport: string =
    'Student name, Student ID, Student SIS ID, Outcome 1 result, Outcome 1 mastery points\n' +
    'test student, 1, student_1, 2.5, 3\n' +
    'other student, 2, student_2, 3.3, 3'

  interface ExportProps {
    courseId: string | number
    gradebookFilters: string[]
  }

  const defaultProps = (props: Partial<ExportProps> = {}): ExportProps => {
    return {
      courseId: '1',
      gradebookFilters: [],
      ...props,
    }
  }

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.get('/courses/1/outcome_rollups.csv', () => {
        return HttpResponse.json({
          mockedExport,
        })
      }),
    )
  })

  describe('useCSVExport hook', () => {
    it('returns the response when an export is requested', async () => {
      const {result, waitFor} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook, exportState, exportData} = result.current

      expect(exportState).toEqual(EXPORT_NOT_STARTED)
      expect(exportData).toStrictEqual([])

      act(() => exportGradebook())

      await waitFor(() => {
        expect(result.current.exportState).toEqual(EXPORT_COMPLETE)
      })

      expect(result.current.exportData).toStrictEqual({
        mockedExport,
      })
    })

    it('calls the /rollups.csv URL with the right parameters', async () => {
      let requestUrl = ''
      let requestParams: URLSearchParams = new URLSearchParams()

      server.use(
        http.get('/courses/1/outcome_rollups.csv', ({request}) => {
          requestUrl = request.url
          requestParams = new URL(request.url).searchParams
          return HttpResponse.json({mockedExport})
        }),
      )

      const {result, waitFor} = renderHook(() =>
        useCSVExport(
          defaultProps({gradebookFilters: ['inactive_enrollments', 'missing_user_rollups']}),
        ),
      )
      const {exportGradebook} = result.current

      act(() => exportGradebook())

      await waitFor(() => {
        expect(result.current.exportState).toEqual(EXPORT_COMPLETE)
      })

      expect(requestUrl).toContain('/courses/1/outcome_rollups.csv')
      expect(requestParams.getAll('exclude[]')).toEqual([
        'inactive_enrollments',
        'missing_user_rollups',
      ])
    })

    it('export state is failed when export fails', async () => {
      server.use(
        http.get('/courses/1/outcome_rollups.csv', () => {
          return HttpResponse.json({error: 'Failed'}, {status: 500})
        }),
      )

      const {result, waitFor} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook} = result.current

      act(() => exportGradebook())

      await waitFor(() => {
        expect(result.current.exportState).toEqual(EXPORT_FAILED)
      })

      expect(result.current.exportData).toStrictEqual([])
    })

    it('shows flash alert when export fails', async () => {
      server.use(
        http.get('/courses/1/outcome_rollups.csv', () => {
          return HttpResponse.json({error: 'Failed'}, {status: 500})
        }),
      )

      const {result, waitFor} = renderHook(() => useCSVExport(defaultProps()))
      const {exportGradebook} = result.current

      act(() => exportGradebook())

      await waitFor(() => {
        expect(result.current.exportState).toEqual(EXPORT_FAILED)
      })

      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Error exporting gradebook',
        type: 'error',
      })
    })
  })
})

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

import useSettings from '../useSettings'
import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

const courseId = 11
const subject = () => renderHook(() => useSettings(courseId))

beforeAll(() => server.listen())
afterAll(() => server.close())

afterEach(() => {
  server.resetHandlers()
})

describe('useSettings', () => {
  it('renders without error', () => {
    server.use(
      http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () => HttpResponse.json({})),
    )
    const {result} = subject()
    expect(result.error).toBeFalsy()
  })

  it('makes a GET request to load the group', async () => {
    let requestMade = false
    server.use(
      http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () => {
        requestMade = true
        return HttpResponse.json({})
      }),
    )
    const {waitForNextUpdate} = subject()
    await waitForNextUpdate()
    expect(requestMade).toBe(true)
  })

  describe('when last_error and last_error_report_id are set on the group', () => {
    it('sets the error with a link to the error report', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () =>
          HttpResponse.json({
            workflow_state: 'errored',
            last_error: 'foo',
            last_error_report_id: 456,
          }),
        ),
      )

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()

      const message = result.current[3].message
      expect(message.type).toBe('a')
      expect(message.props.href).toBe('/error_reports/456')
      expect(message.props.children).toBe('An error occurred during the sync process: foo')
    })
  })

  describe('toggleEnabled', () => {
    it('enables the integration when it is disabled', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () => HttpResponse.json({})),
        http.post(`/api/v1/courses/${courseId}/microsoft_sync/group`, () =>
          HttpResponse.json({}, {status: 201}),
        ),
      )

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()

      const toggleEnabled = result.current[4]
      await act(toggleEnabled)
    })

    it('disables the integration when it is enabled', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () =>
          HttpResponse.json({workflow_state: 'active'}),
        ),
        http.delete(`/api/v1/courses/${courseId}/microsoft_sync/group`, () =>
          HttpResponse.json({}, {status: 201}),
        ),
      )

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()

      const toggleEnabled = result.current[4]
      await act(toggleEnabled)
    })

    it('uses the error message in the response if it exists', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () => HttpResponse.json({})),
        http.post(`/api/v1/courses/${courseId}/microsoft_sync/group`, () =>
          HttpResponse.json({message: 'Something bad happened, sorry'}, {status: 422}),
        ),
      )

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()

      const toggleEnabled = result.current[4]
      await act(toggleEnabled)

      expect(result.current[3]).toEqual({message: 'Something bad happened, sorry'})
    })

    it('uses the message in the Error object if no message is in the response', async () => {
      server.use(
        http.get(`/api/v1/courses/${courseId}/microsoft_sync/group`, () => HttpResponse.json({})),
        http.post(
          `/api/v1/courses/${courseId}/microsoft_sync/group`,
          () => new HttpResponse(null, {status: 400}),
        ),
      )

      const {result, waitForNextUpdate} = subject()
      await waitForNextUpdate()

      const toggleEnabled = result.current[4]
      await act(toggleEnabled)

      expect(result.current[3]).toContain('400')
    })
  })
})

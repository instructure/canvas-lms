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
import useFetchApi from '@canvas/use-fetch-api-hook'
import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import axios from 'axios'

jest.mock('@canvas/use-fetch-api-hook')
jest.mock('axios')

const courseId = 11
const subject = () => renderHook(() => useSettings(courseId))

afterEach(() => {
  useFetchApi.mockClear()
  axios.request.mockClear()
})

describe('useSettings', () => {
  it('renders without error', () => {
    const {result} = subject()
    expect(result.error).toBeFalsy()
  })

  it('makes a GET request to load the group', () => {
    subject()
    const lastCall = useFetchApi.mock.calls.pop()

    expect(lastCall[0]).toMatchObject({
      path: `/api/v1/courses/${courseId}/microsoft_sync/group`,
    })
  })

  describe('when last_error and last_error_report_id are set on the group', () => {
    it('sets the error with a link to the error report', () => {
      useFetchApi.mockImplementationOnce(({success}) => {
        success({workflow_state: 'errored', last_error: 'foo', last_error_report_id: 456})
      })

      const result = subject().result
      const message = result.current[3].message
      expect(message.type).toBe('a')
      expect(message.props.href).toBe('/error_reports/456')
      expect(message.props.children).toBe('An error occurred during the sync process: foo')
    })
  })

  describe('toggleEnabled', () => {
    it('enables the integration when it is disabled', async () => {
      const {result} = subject()
      const toggleEnabled = result.current[4]

      axios.request.mockImplementationOnce(_req => Promise.resolve({status: 201, data: {}}))

      await act(toggleEnabled)

      expect(axios.request).toHaveBeenLastCalledWith({
        method: 'post',
        url: `/api/v1/courses/${courseId}/microsoft_sync/group`,
      })
    })

    it('disables the integration when it is enabled', async () => {
      useFetchApi.mockImplementationOnce(({success}) => {
        success({workflow_state: 'active'})
      })

      const {result} = subject()
      const toggleEnabled = result.current[4]

      axios.request.mockImplementationOnce(_req => Promise.resolve({status: 201, data: {}}))

      await act(toggleEnabled)

      expect(axios.request).toHaveBeenLastCalledWith({
        method: 'delete',
        url: `/api/v1/courses/${courseId}/microsoft_sync/group`,
      })
    })

    it('uses the error message in the response if it exists', async () => {
      const {result} = subject()
      const toggleEnabled = result.current[4]
      const e = new Error('422 error')
      e.response = {status: 422, data: {message: 'Something bad happened, sorry'}}

      axios.request.mockImplementationOnce(_req => Promise.reject(e))

      await act(toggleEnabled)

      expect(result.current[3]).toEqual({message: 'Something bad happened, sorry'})
    })

    it('uses the message in the Error object if no message is in the response', async () => {
      const {result} = subject()
      const toggleEnabled = result.current[4]

      const e = new Error('400 error')
      e.response = {status: 400}

      axios.request.mockImplementationOnce(_req => Promise.reject(e))

      await act(toggleEnabled)

      expect(result.current[3]).toBe('400 error')
    })
  })
})

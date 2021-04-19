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
      path: `/api/v1/courses/${courseId}/microsoft_sync/group`
    })
  })

  describe('toggleEnabled', () => {
    it('enables the integration when it is disabled', () => {
      const {result} = subject()
      const toggleEnabled = result.current[4]

      act(() => {
        toggleEnabled()
      })

      expect(axios.request).toHaveBeenLastCalledWith({
        method: 'post',
        url: `/api/v1/courses/${courseId}/microsoft_sync/group`
      })
    })

    it('disables the integration when it is enabled', () => {
      useFetchApi.mockImplementationOnce(({success}) => {
        success({workflow_state: 'active'})
      })

      const {result} = subject()
      const toggleEnabled = result.current[4]

      act(() => {
        toggleEnabled()
      })

      expect(axios.request).toHaveBeenLastCalledWith({
        method: 'delete',
        url: `/api/v1/courses/${courseId}/microsoft_sync/group`
      })
    })
  })
})

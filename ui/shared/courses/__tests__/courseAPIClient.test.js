/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {forceReload} from '@canvas/util/globalUtils'
import $ from 'jquery'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import * as apiClient from '../courseAPIClient'

jest.mock('@canvas/util/globalUtils', () => ({
  forceReload: jest.fn(),
}))

const server = setupServer()

describe('apiClient', () => {
  const {location: savedLocation} = window

  beforeAll(() => {
    server.listen()
    $.flashWarning = jest.fn()
    $.flashError = jest.fn()
  })

  afterEach(() => {
    server.resetHandlers()
    $.flashWarning.mockClear()
    $.flashError.mockClear()
    forceReload.mockClear()
  })

  afterAll(() => {
    server.close()
    $.flashWarning.mockRestore()
    $.flashError.mockRestore()
  })

  describe('publishCourse', () => {
    it('reloads the window after upload with the proper param', async () => {
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', async ({request}) => {
          const body = await request.json()
          expect(body).toEqual({course: {event: 'offer'}})
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({})
        }),
      )

      apiClient.publishCourse({courseId: '1'})
      await promise
      expect(forceReload).toHaveBeenCalled()
    })

    it('calls onSuccess function on success if provided', async () => {
      const onSuccess = jest.fn()
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', () => {
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({})
        }),
      )

      apiClient.publishCourse({courseId: '1', onSuccess})
      await promise
      expect(onSuccess).toHaveBeenCalled()
    })

    it('flashes registration message on 401', async () => {
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', () => {
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({status: 'unverified'}, {status: 401})
        }),
      )

      apiClient.publishCourse({courseId: '1'})
      await promise
      expect(window.location.search).toBe('')
      expect($.flashWarning).toHaveBeenCalledWith(
        expect.stringContaining('Complete registration by clicking the'),
      )
    })

    it('flashes an error on failure', async () => {
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', () => {
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({}, {status: 404})
        }),
      )

      apiClient.publishCourse({courseId: '1'})
      await promise
      expect(window.location.search).toBe('')
      expect($.flashError).toHaveBeenCalledWith('An error ocurred while publishing course')
    })
  })

  describe('unpublishCourse', () => {
    it('reloads the window after upload with the proper param', async () => {
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', async ({request}) => {
          const body = await request.json()
          expect(body).toEqual({course: {event: 'claim'}})
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({})
        }),
      )

      apiClient.unpublishCourse({courseId: '1'})
      await promise
      expect(forceReload).toHaveBeenCalled()
    })

    it('calls onSuccess function on success if provided', async () => {
      const onSuccess = jest.fn()
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', () => {
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({})
        }),
      )

      apiClient.unpublishCourse({courseId: '1', onSuccess})
      await promise
      expect(onSuccess).toHaveBeenCalled()
    })

    it('flashes an error on failure', async () => {
      let resolvePromise
      const promise = new Promise(resolve => {
        resolvePromise = resolve
      })

      server.use(
        http.put('/api/v1/courses/1', () => {
          setTimeout(() => resolvePromise(), 0)
          return HttpResponse.json({}, {status: 404})
        }),
      )

      apiClient.unpublishCourse({courseId: '1'})
      await promise
      expect(window.location.search).toBe('')
      expect($.flashError).toHaveBeenCalledWith('An error occurred while unpublishing course')
    })
  })
})

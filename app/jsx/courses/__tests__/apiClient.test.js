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

import moxios from 'moxios'
import $ from 'jquery'
import * as apiClient from '../apiClient'

describe('apiClient', () => {
  const {location: savedLocation} = window

  beforeAll(() => {
    $.flashWarning = jest.fn()
    $.flashError = jest.fn()
  })

  beforeEach(() => {
    delete window.location
    window.location = {reload: jest.fn()}
    moxios.install()
  })

  afterEach(() => {
    window.location = savedLocation
    moxios.uninstall()
    $.flashWarning.mockClear()
    $.flashError.mockClear()
  })

  afterAll(() => {
    $.flashWarning.mockRestore()
    $.flashError.mockRestore()
  })

  describe('publishCourse', () => {
    it('reloads the window after upload', done => {
      moxios.stubRequest('/api/v1/courses/1', {
        status: 200,
        response: {}
      })
      apiClient.publishCourse({courseId: 1})
      moxios.wait(() => {
        expect(window.location.reload).toHaveBeenCalled()
        done()
      })
    })

    it('flashes registration message on 401', done => {
      moxios.stubRequest('/api/v1/courses/1', {
        status: 401,
        response: {
          status: 'unverified'
        }
      })
      apiClient.publishCourse({courseId: 1})
      moxios.wait(() => {
        expect(window.location.reload).not.toHaveBeenCalled()
        expect($.flashWarning).toHaveBeenCalledWith(
          'Complete registration by clicking the “finish the registration process” link sent to your email.'
        )
        done()
      })
    })

    it('flashes an error on failure', done => {
      moxios.stubRequest('/api/v1/courses/1', {
        status: 404
      })
      apiClient.publishCourse({courseId: 1})
      moxios.wait(() => {
        expect(window.location.reload).not.toHaveBeenCalled()
        expect($.flashError).toHaveBeenCalledWith('An error ocurred while publishing course')
        done()
      })
    })
  })
})

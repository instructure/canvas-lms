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

import fakeENV from '@canvas/test-utils/fakeENV'
import {editView} from './utils'
import $ from 'jquery'
import '@canvas/jquery/jquery.simulate'
import fetchMock from 'fetch-mock'

// Suppress React warnings
const originalConsoleError = console.error
const originalConsoleWarn = console.warn
beforeAll(() => {
  console.error = (...args) => {
    if (
      typeof args[0] === 'string' &&
      (args[0].includes('Warning: React does not recognize') ||
        args[0].includes('Warning: componentWillMount has been renamed') ||
        args[0].includes('Target container is not a DOM element'))
    )
      return
    originalConsoleError.call(console, ...args)
  }
  console.warn = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: componentWillMount has been renamed')
    )
      return
    originalConsoleWarn.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalConsoleError
  console.warn = originalConsoleWarn
})

describe('EditView', () => {
  let $container

  beforeEach(() => {
    $container = $('<div>').appendTo(document.body)
  })

  afterEach(() => {
    $container.remove()
  })

  describe('Usage Rights', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.USAGE_RIGHTS_REQUIRED = true
      ENV.PERMISSIONS = {manage_files: true}
      ENV.context_asset_string = 'course_1'
      ENV.SETTINGS = {suppress_assignments: false}

      // Mock API endpoints
      fetchMock
        .get('http://api/folders?contextType=user&contextId=1', 200)
        .get('path:/api/session', 200)
        .get('path:/api/v1/courses/1/lti_apps/launch_definitions', {
          tools: [],
        })
        .post('path:/api/graphql', {data: {}})
        .get('*', 200) // Catch any other requests
    })

    afterEach(() => {
      fakeENV.teardown()
      fetchMock.restore()
    })

    it('renders usage rights control when CAN_ATTACH is true', () => {
      const view = editView({permissions: {CAN_ATTACH: true}})
      $container.append(view.$el)
      expect(view.$el.find('#usage_rights_control')).toHaveLength(1)
    })

    it('does not render usage rights control when CAN_ATTACH is false', () => {
      const view = editView({permissions: {CAN_ATTACH: false}})
      $container.append(view.$el)
      expect(view.$el.find('#usage_rights_control')).toHaveLength(0)
    })
  })
})

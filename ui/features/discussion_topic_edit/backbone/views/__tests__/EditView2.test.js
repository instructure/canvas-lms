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
    fakeENV.setup()
    ENV.SETTINGS = {suppress_assignments: false}

    // Mock API endpoints
    fetchMock
      .get('path:/api/v1/courses/1/lti_apps/launch_definitions', {
        tools: [],
      })
      .get('*', 200) // Catch any other requests
  })

  afterEach(() => {
    $container.remove()
    fakeENV.teardown()
    fetchMock.restore()
  })

  describe('Sections Specific', () => {
    it('allows discussion to save when section specific has errors has no section', () => {
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: false}}
      const view = editView({withAssignment: true})
      $container.append(view.$el)

      const title = 'a'.repeat(10)
      const {assignment} = view
      assignment.attributes.post_to_sis = '1'

      const errors = view.validateBeforeSave(
        {
          title,
          set_assignment: '1',
          assignment,
          specific_sections: null,
        },
        [],
      )

      expect(Object.keys(errors)).toHaveLength(0)
    })

    it('allows announcement to save when section specific has a section', () => {
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
      const view = editView({withAssignment: false})
      $container.append(view.$el)

      const title = 'a'.repeat(10)
      const {assignment} = view
      assignment.attributes.post_to_sis = '1'

      const errors = view.validateBeforeSave(
        {
          title,
          specific_sections: ['fake_section'],
        },
        [],
      )

      expect(Object.keys(errors)).toHaveLength(0)
    })

    it('allows group announcements to be saved without a section', () => {
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.CONTEXT_ID = 1
      ENV.context_asset_string = 'group_1'
      ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
      const view = editView({withAssignment: false})
      $container.append(view.$el)

      const title = 'a'.repeat(10)
      const {assignment} = view
      assignment.attributes.post_to_sis = '1'

      const errors = view.validateBeforeSave(
        {
          title,
          specific_sections: null,
        },
        [],
      )

      expect(Object.keys(errors)).toHaveLength(0)
    })

    it('requires section for course announcements if enabled', () => {
      ENV.should_log = true
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.CONTEXT_ID = 1
      ENV.context_asset_string = 'course_1'
      ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
      const view = editView({withAssignment: false})
      $container.append(view.$el)

      const title = 'a'.repeat(10)
      const {assignment} = view
      assignment.attributes.post_to_sis = '1'

      const errors = view.validateBeforeSave(
        {
          title,
          specific_sections: null,
        },
        [],
      )

      expect(Object.keys(errors)).toHaveLength(1)
      expect(Object.keys(errors)[0]).toBe('specific_sections')
    })
  })
})

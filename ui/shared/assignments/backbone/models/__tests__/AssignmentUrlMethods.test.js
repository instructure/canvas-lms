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

import {getUrlWithHorizonParams} from '@canvas/horizon/utils'
import fakeENV from '@canvas/test-utils/fakeENV'
import Assignment from '../Assignment'

// Mock the horizon utils module
vi.mock('@canvas/horizon/utils', () => ({
  getUrlWithHorizonParams: vi.fn(),
}))

describe('Assignment URL Methods', () => {
  let originalLocation

  beforeEach(() => {
    fakeENV.setup()
    originalLocation = window.location
    delete window.location
    window.location = {href: '', origin: 'https://canvas.instructure.com'}
    // Clear all mocks before each test
    vi.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
    window.location = originalLocation
  })

  describe('htmlUrl', () => {
    test('calls getUrlWithHorizonParams for regular assignment', () => {
      getUrlWithHorizonParams.mockReturnValue('https://example.com/assignments/1?content_only=true')

      const assignment = new Assignment({html_url: 'https://example.com/assignments/1'})
      const result = assignment.htmlUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1')
      expect(result).toBe('https://example.com/assignments/1?content_only=true')
    })

    test('calls getUrlWithHorizonParams for quiz LTI assignment with quiz_lti param', () => {
      getUrlWithHorizonParams.mockReturnValue(
        'https://example.com/assignments/1/edit?quiz_lti=true&content_only=true',
      )

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage to return true
      window.ENV = {PERMISSIONS: {manage: true}}

      const result = assignment.htmlUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith(
        'https://example.com/assignments/1/edit',
        {quiz_lti: true},
      )
      expect(result).toBe('https://example.com/assignments/1/edit?quiz_lti=true&content_only=true')
    })

    test('uses regular html_url for quiz LTI assignment when user cannot manage', () => {
      getUrlWithHorizonParams.mockReturnValue('https://example.com/assignments/1?content_only=true')

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage to return false
      window.ENV = {PERMISSIONS: {manage: false}}

      const result = assignment.htmlUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1')
      expect(result).toBe('https://example.com/assignments/1?content_only=true')
    })
  })

  describe('htmlEditUrl', () => {
    test('calls getUrlWithHorizonParams with edit path', () => {
      getUrlWithHorizonParams.mockReturnValue(
        'https://example.com/assignments/1/edit?content_only=true',
      )

      const assignment = new Assignment({html_url: 'https://example.com/assignments/1'})
      const result = assignment.htmlEditUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1/edit')
      expect(result).toBe('https://example.com/assignments/1/edit?content_only=true')
    })
  })

  describe('htmlBuildUrl', () => {
    test('calls getUrlWithHorizonParams for regular assignment', () => {
      getUrlWithHorizonParams.mockReturnValue('https://example.com/assignments/1?content_only=true')

      const assignment = new Assignment({html_url: 'https://example.com/assignments/1'})
      const result = assignment.htmlBuildUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1')
      expect(result).toBe('https://example.com/assignments/1?content_only=true')
    })

    test('calls getUrlWithHorizonParams with display param for quiz LTI assignment', () => {
      getUrlWithHorizonParams.mockReturnValue(
        'https://example.com/assignments/1?display=full_width&content_only=true',
      )

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage to return true and ensure FEATURES exists
      window.ENV = {
        PERMISSIONS: {manage: true},
        FEATURES: {},
      }

      const result = assignment.htmlBuildUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1', {
        display: 'full_width',
      })
      expect(result).toBe('https://example.com/assignments/1?display=full_width&content_only=true')
    })

    test('uses full_width_with_nav display when new_quizzes_navigation_updates feature is enabled', () => {
      getUrlWithHorizonParams.mockReturnValue(
        'https://example.com/assignments/1?display=full_width_with_nav&content_only=true',
      )

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage and feature flag
      window.ENV = {
        PERMISSIONS: {manage: true},
        FEATURES: {new_quizzes_navigation_updates: true},
      }

      const result = assignment.htmlBuildUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1', {
        display: 'full_width_with_nav',
      })
      expect(result).toBe(
        'https://example.com/assignments/1?display=full_width_with_nav&content_only=true',
      )
    })

    test('uses regular html_url for quiz LTI assignment when user cannot manage', () => {
      getUrlWithHorizonParams.mockReturnValue('https://example.com/assignments/1?content_only=true')

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage to return false
      window.ENV = {PERMISSIONS: {manage: false}}

      const result = assignment.htmlBuildUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1')
      expect(result).toBe('https://example.com/assignments/1?content_only=true')
    })
  })

  describe('horizon parameter integration', () => {
    test('all URL methods work correctly when horizon course is enabled', () => {
      // Setup horizon course environment
      window.ENV.horizon_course = true
      getUrlWithHorizonParams.mockImplementation((url, additionalParams) => {
        const urlObj = new URL(url, 'https://canvas.instructure.com')
        urlObj.searchParams.set('content_only', 'true')
        urlObj.searchParams.set('instui_theme', 'career')
        urlObj.searchParams.set('force_classic', 'true')

        if (additionalParams) {
          Object.entries(additionalParams).forEach(([key, value]) => {
            urlObj.searchParams.set(key, value)
          })
        }

        return urlObj.toString()
      })

      const assignment = new Assignment({html_url: 'https://example.com/assignments/1'})

      const htmlUrl = assignment.htmlUrl()
      const editUrl = assignment.htmlEditUrl()
      const buildUrl = assignment.htmlBuildUrl()

      expect(htmlUrl).toContain('content_only=true')
      expect(htmlUrl).toContain('instui_theme=career')
      expect(htmlUrl).toContain('force_classic=true')

      expect(editUrl).toContain('content_only=true')
      expect(buildUrl).toContain('content_only=true')
    })

    test('all URL methods work correctly when horizon course is disabled', () => {
      // Setup non-horizon course environment
      window.ENV.horizon_course = false
      // Mock implementation should append additionalParams even when not in horizon course
      getUrlWithHorizonParams.mockImplementation((url, additionalParams = {}) => {
        if (Object.keys(additionalParams).length === 0) {
          return url
        }
        const urlObj = new URL(url, 'https://canvas.instructure.com')
        Object.entries(additionalParams).forEach(([key, value]) => {
          urlObj.searchParams.set(key, value)
        })
        return urlObj.toString()
      })

      const assignment = new Assignment({html_url: 'https://example.com/assignments/1'})

      const htmlUrl = assignment.htmlUrl()
      const editUrl = assignment.htmlEditUrl()
      const buildUrl = assignment.htmlBuildUrl()

      expect(htmlUrl).toBe('https://example.com/assignments/1')
      expect(editUrl).toBe('https://example.com/assignments/1/edit')
      expect(buildUrl).toBe('https://example.com/assignments/1')

      expect(htmlUrl).not.toContain('content_only')
      expect(editUrl).not.toContain('content_only')
      expect(buildUrl).not.toContain('content_only')
    })

    test('display param is appended even when horizon course is disabled for quiz LTI assignments', () => {
      // Setup non-horizon course environment
      window.ENV.horizon_course = false
      // Mock implementation should append additionalParams even when not in horizon course
      getUrlWithHorizonParams.mockImplementation((url, additionalParams = {}) => {
        if (Object.keys(additionalParams).length === 0) {
          return url
        }
        const urlObj = new URL(url, 'https://canvas.instructure.com')
        Object.entries(additionalParams).forEach(([key, value]) => {
          urlObj.searchParams.set(key, value)
        })
        return urlObj.toString()
      })

      const assignment = new Assignment({
        html_url: 'https://example.com/assignments/1',
        is_quiz_lti_assignment: true,
      })

      // Mock canManage and feature flag
      window.ENV = {
        ...window.ENV,
        PERMISSIONS: {manage: true},
        FEATURES: {new_quizzes_navigation_updates: true},
      }

      const buildUrl = assignment.htmlBuildUrl()

      expect(getUrlWithHorizonParams).toHaveBeenCalledWith('https://example.com/assignments/1', {
        display: 'full_width_with_nav',
      })
      expect(buildUrl).toContain('display=full_width_with_nav')
      expect(buildUrl).not.toContain('content_only')
    })
  })
})

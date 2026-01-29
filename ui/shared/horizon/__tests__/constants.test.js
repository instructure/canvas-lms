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
 *
 * @vitest-environment-options {"url": "https://canvas.instructure.com"}
 */

import fakeENV from '@canvas/test-utils/fakeENV'
import {HORIZON_PARAMS, buildHorizonUrl, getUrlWithHorizonParams} from '../utils'

describe('Horizon Constants', () => {
  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('HORIZON_PARAMS', () => {
    test('contains expected horizon parameters', () => {
      expect(HORIZON_PARAMS).toEqual({
        content_only: 'true',
        instui_theme: 'career',
        force_classic: 'true',
        hide_global_nav: 'true',
      })
    })
  })

  describe('buildHorizonUrl', () => {
    test('builds URL with horizon parameters', () => {
      const result = buildHorizonUrl('https://example.com/path')
      const url = new URL(result)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('instui_theme')).toBe('career')
      expect(url.searchParams.get('force_classic')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
    })

    test('builds URL with horizon parameters and additional params', () => {
      const result = buildHorizonUrl('https://example.com/path', {foo: 'bar', baz: 'qux'})
      const url = new URL(result)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('instui_theme')).toBe('career')
      expect(url.searchParams.get('force_classic')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
      expect(url.searchParams.get('foo')).toBe('bar')
      expect(url.searchParams.get('baz')).toBe('qux')
    })

    test('additional params override horizon params when keys conflict', () => {
      const result = buildHorizonUrl('https://example.com/path', {instui_theme: 'custom'})
      const url = new URL(result)

      expect(url.searchParams.get('instui_theme')).toBe('custom')
    })

    test('works with relative URLs using window.location.origin', () => {
      const result = buildHorizonUrl('/courses/1/assignments')
      const url = new URL(result)

      expect(url.origin).toBe('https://canvas.instructure.com')
      expect(url.pathname).toBe('/courses/1/assignments')
      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
    })
  })

  describe('redirectWithHorizonParams', () => {
    test('calls buildHorizonUrl with correct params when ENV.horizon_course is true', () => {
      ENV.horizon_course = true

      const expectedUrl = buildHorizonUrl('https://example.com/path')
      const url = new URL(expectedUrl)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('instui_theme')).toBe('career')
      expect(url.searchParams.get('force_classic')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
    })

    test('calls buildHorizonUrl with additional params when provided', () => {
      ENV.horizon_course = true

      const expectedUrl = buildHorizonUrl('https://example.com/path', {display: 'full_width'})
      const url = new URL(expectedUrl)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
      expect(url.searchParams.get('display')).toBe('full_width')
    })

    test('uses URL directly when ENV.horizon_course is false', () => {
      ENV.horizon_course = false

      expect(ENV.horizon_course).toBe(false)
    })

    test('uses URL directly when ENV.horizon_course is undefined', () => {
      delete ENV.horizon_course

      expect(ENV.horizon_course).toBeUndefined()
    })
  })

  describe('getUrlWithHorizonParams', () => {
    test('returns URL with horizon params when ENV.horizon_course is true', () => {
      ENV.horizon_course = true

      const result = getUrlWithHorizonParams('https://example.com/path')
      const url = new URL(result)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('instui_theme')).toBe('career')
      expect(url.searchParams.get('force_classic')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
    })

    test('returns URL with horizon params and additional params when ENV.horizon_course is true', () => {
      ENV.horizon_course = true

      const result = getUrlWithHorizonParams('https://example.com/path', {quiz_lti: 'true'})
      const url = new URL(result)

      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
      expect(url.searchParams.get('quiz_lti')).toBe('true')
    })

    test('returns original URL without horizon params when ENV.horizon_course is false', () => {
      ENV.horizon_course = false

      const result = getUrlWithHorizonParams('https://example.com/path?existing=param')

      expect(result).toBe('https://example.com/path?existing=param')
    })

    test('returns URL with additional params but no horizon params when ENV.horizon_course is false', () => {
      ENV.horizon_course = false

      const result = getUrlWithHorizonParams('https://example.com/path', {display: 'full_width'})
      const url = new URL(result)

      expect(url.searchParams.get('display')).toBe('full_width')
      expect(url.searchParams.get('content_only')).toBeNull()
      expect(url.searchParams.get('instui_theme')).toBeNull()
      expect(url.searchParams.get('force_classic')).toBeNull()
      expect(url.searchParams.get('hide_global_nav')).toBeNull()
    })

    test('returns original URL without horizon params when ENV.horizon_course is undefined', () => {
      delete ENV.horizon_course

      const result = getUrlWithHorizonParams('https://example.com/path')

      expect(result).toBe('https://example.com/path')
    })

    test('returns URL with additional params but no horizon params when ENV.horizon_course is undefined', () => {
      delete ENV.horizon_course

      const result = getUrlWithHorizonParams('https://example.com/path', {
        display: 'full_width_with_nav',
      })
      const url = new URL(result)

      expect(url.searchParams.get('display')).toBe('full_width_with_nav')
      expect(url.searchParams.get('content_only')).toBeNull()
      expect(url.searchParams.get('instui_theme')).toBeNull()
      expect(url.searchParams.get('force_classic')).toBeNull()
      expect(url.searchParams.get('hide_global_nav')).toBeNull()
    })

    test('preserves existing query parameters in horizon course', () => {
      ENV.horizon_course = true

      const result = getUrlWithHorizonParams('https://example.com/path?existing=param&other=value')
      const url = new URL(result)

      expect(url.searchParams.get('existing')).toBe('param')
      expect(url.searchParams.get('other')).toBe('value')
      expect(url.searchParams.get('content_only')).toBe('true')
      expect(url.searchParams.get('hide_global_nav')).toBe('true')
    })

    test('preserves existing query parameters when not in horizon course with additional params', () => {
      ENV.horizon_course = false

      const result = getUrlWithHorizonParams('https://example.com/path?existing=param', {
        display: 'full_width',
      })
      const url = new URL(result)

      expect(url.searchParams.get('existing')).toBe('param')
      expect(url.searchParams.get('display')).toBe('full_width')
      expect(url.searchParams.get('content_only')).toBeNull()
      expect(url.searchParams.get('hide_global_nav')).toBeNull()
    })
  })
})

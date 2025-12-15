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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'

describe('$.fn.defaultAjaxError', () => {
  let storedInstEnv

  beforeEach(() => {
    storedInstEnv = window.INST?.environment
    window.INST = window.INST || {}
    $.ajaxJSON.unhandledXHRs = []
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    window.INST.environment = storedInstEnv
    $('#fixtures').empty()
  })

  it('calls the function if not in production', () => {
    expect(window.INST.environment).not.toBe('production')
    expect($.ajaxJSON.unhandledXHRs).toHaveLength(0)

    const mockCallback = vi.fn()
    $('#fixtures').defaultAjaxError(mockCallback)

    const xhr = {
      status: 200,
      responseText: '{"status": "ok"}',
    }
    $.fn.defaultAjaxError.func({}, xhr)

    expect(mockCallback).toHaveBeenCalled()
  })

  it('calls the function if request is unhandled', () => {
    window.INST.environment = 'production'
    const xhr = {
      status: 400,
      responseText: '{"status": "ok"}',
    }
    $.ajaxJSON.unhandledXHRs.push(xhr)

    const mockCallback = vi.fn()
    $('#fixtures').defaultAjaxError(mockCallback)
    $.fn.defaultAjaxError.func({}, xhr)

    expect(mockCallback).toHaveBeenCalled()
  })

  it('calls the function if unauthenticated', () => {
    window.INST.environment = 'production'
    expect($.ajaxJSON.unhandledXHRs).toHaveLength(0)

    const mockCallback = vi.fn()
    $('#fixtures').defaultAjaxError(mockCallback)

    const xhr = {
      status: 401,
      responseText: '{"status": "unauthenticated"}',
    }
    $.fn.defaultAjaxError.func({}, xhr)

    expect(mockCallback).toHaveBeenCalled()
  })
})

describe('$.ajaxJSON.isUnauthenticated', () => {
  it('returns false if status is not 401', () => {
    expect($.ajaxJSON.isUnauthenticated({status: 200})).toBe(false)
  })

  it('returns false if status is 401 but response is empty', () => {
    const xhr = {
      status: 401,
      responseText: '',
    }
    expect($.ajaxJSON.isUnauthenticated(xhr)).toBe(false)
  })

  it('returns false if status is 401 but message is not unauthenticated', () => {
    const xhr = {
      status: 401,
      responseText: '{"status": "unauthorized"}',
    }
    expect($.ajaxJSON.isUnauthenticated(xhr)).toBe(false)
  })

  it('returns true if status is 401 and message is unauthenticated', () => {
    const xhr = {
      status: 401,
      responseText: '{"status": "unauthenticated"}',
    }
    expect($.ajaxJSON.isUnauthenticated(xhr)).toBe(true)
  })
})

describe('$.ajaxJSON.abortRequest', () => {
  it('aborts xhr if not done', () => {
    const mockAbort = vi.fn()
    const xhr = {abort: mockAbort}
    $.ajaxJSON.abortRequest(xhr)
    expect(mockAbort).toHaveBeenCalled()
  })

  it('does not call callback after aborting', () => {
    const xhr = {
      readyState: 0,
      abort: vi.fn(),
      onreadystatechange: null,
    }
    const mockCallback = vi.fn()

    $.ajaxJSON('/api', 'GET', {}, mockCallback, mockCallback)
    $.ajaxJSON.abortRequest(xhr)

    xhr.readyState = 4 // DONE
    xhr.onreadystatechange?.()

    expect(mockCallback).not.toHaveBeenCalled()
  })
})

describe('$.ajaxJSON headers option', () => {
  it('includes headers in ajax params when provided', () => {
    const mockAjax = vi.fn().mockReturnValue({then: () => ({fail: () => ({always: () => {}})})})
    const originalAjax = $.ajax
    $.ajax = mockAjax

    const customHeaders = {'X-Custom-Header': 'test-value'}
    $.ajaxJSON('/test', 'GET', {}, undefined, undefined, {headers: customHeaders})

    expect(mockAjax).toHaveBeenCalledWith(
      expect.objectContaining({
        headers: customHeaders,
      }),
    )

    $.ajax = originalAjax
  })

  it('ignores invalid headers', () => {
    const mockAjax = vi.fn().mockReturnValue({then: () => ({fail: () => ({always: () => {}})})})
    const originalAjax = $.ajax
    $.ajax = mockAjax

    $.ajaxJSON('/test', 'GET', {}, undefined, undefined, {headers: null})

    expect(mockAjax).toHaveBeenCalledWith(
      expect.not.objectContaining({
        headers: expect.anything(),
      }),
    )

    $.ajax = originalAjax
  })
})

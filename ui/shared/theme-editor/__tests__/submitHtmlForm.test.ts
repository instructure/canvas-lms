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

import {submitHtmlForm} from '../submitHtmlForm'

describe('submitHtmlForm', () => {
  let mockSubmit: jest.SpyInstance

  beforeEach(() => {
    // Mock form.submit() since jsdom doesn't implement it
    mockSubmit = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation(() => {})
    // Mock getCookie to return a test CSRF token
    document.cookie = '_csrf_token=test-csrf-token'
  })

  afterEach(() => {
    mockSubmit.mockRestore()
    // Clean up any forms created during tests
    document.querySelectorAll('form').forEach(form => form.remove())
  })

  it('creates a form with the correct action and method', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'DELETE')

    const form = document.querySelector('form')
    expect(form).not.toBeNull()
    expect(form?.action).toContain(action)
    expect(form?.method).toBe('post') // HTML forms use POST for all requests
  })

  it('adds _method hidden input for DELETE requests', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'DELETE')

    const methodInput = document.querySelector('input[name="_method"]') as HTMLInputElement
    expect(methodInput).not.toBeNull()
    expect(methodInput?.value).toBe('DELETE')
  })

  it('does not add _method input for POST requests', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'POST')

    const methodInput = document.querySelector('input[name="_method"]')
    expect(methodInput).toBeNull()
  })

  it('adds CSRF token as hidden input', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'POST')

    const csrfInput = document.querySelector('input[name="authenticity_token"]') as HTMLInputElement
    expect(csrfInput).not.toBeNull()
    expect(csrfInput?.type).toBe('hidden')
    expect(csrfInput?.value).toBe('test-csrf-token')
  })

  it('adds brand_config_md5 when provided', () => {
    const action = '/accounts/123/brand_configs/save_to_user_session'
    const md5 = '0123456789abcdef0123456789abcdef'
    submitHtmlForm(action, 'POST', md5)

    const md5Input = document.querySelector('input[name="brand_config_md5"]') as HTMLInputElement
    expect(md5Input).not.toBeNull()
    expect(md5Input?.type).toBe('hidden')
    expect(md5Input?.value).toBe(md5)
  })

  it('does not add brand_config_md5 when not provided', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'POST')

    const md5Input = document.querySelector('input[name="brand_config_md5"]')
    expect(md5Input).toBeNull()
  })

  it('submits the form', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'DELETE')

    expect(mockSubmit).toHaveBeenCalledTimes(1)
  })

  it('hides the form from view', () => {
    const action = '/accounts/123/brand_configs'
    submitHtmlForm(action, 'DELETE')

    const form = document.querySelector('form') as HTMLFormElement
    expect(form?.style.display).toBe('none')
  })
})

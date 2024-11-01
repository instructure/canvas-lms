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

import {renderHook} from '@testing-library/react-hooks'
import {useNewLoginData} from '../useNewLoginData'

const createMockContainer = (
  authProviders: string | null,
  loginHandleName: string | null,
  loginLogoUrl: string | null,
  loginLogoAlt: string | null,
  bodyBgColor: string | null,
  bodyBgImage: string | null,
  isPreviewMode: string | null
) => {
  const container = document.createElement('div')
  container.id = 'new_login_data'
  if (authProviders !== null) {
    container.setAttribute('data-auth-providers', authProviders)
  }
  if (loginHandleName !== null) {
    container.setAttribute('data-login-handle-name', loginHandleName)
  }
  if (loginLogoUrl !== null) {
    container.setAttribute('data-login-logo-url', loginLogoUrl)
  }
  if (loginLogoAlt !== null) {
    container.setAttribute('data-login-logo-alt', loginLogoAlt)
  }
  if (bodyBgColor !== null) {
    container.setAttribute('data-body-bg-color', bodyBgColor)
  }
  if (bodyBgImage !== null) {
    container.setAttribute('data-body-bg-image', bodyBgImage)
  }
  if (isPreviewMode !== null) {
    container.setAttribute('data-is-preview-mode', isPreviewMode)
  }
  document.body.appendChild(container)
}

describe('useNewLoginData', () => {
  afterEach(() => {
    const container = document.getElementById('new_login_data')
    if (container) {
      container.remove()
    }
  })

  it('mounts without crashing', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current).toBeDefined()
  })

  it('returns default undefined values when container is not present at all', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toBeUndefined()
    expect(result.current.loginLogoUrl).toBeUndefined()
    expect(result.current.loginLogoAlt).toBeUndefined()
    expect(result.current.loginHandleName).toBeUndefined()
    expect(result.current.bodyBgColor).toBeUndefined()
    expect(result.current.bodyBgImage).toBeUndefined()
    expect(result.current.isPreviewMode).toBeUndefined()
  })

  it('returns parsed values from the container when present', () => {
    createMockContainer(
      JSON.stringify([{id: '1', name: 'Google', auth_type: 'google'}]),
      'Username',
      'https://example.com/logo.png',
      'Custom Alt Text',
      '#ffffff',
      'https://example.com/bg.png',
      'true'
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toEqual([{id: '1', name: 'Google', auth_type: 'google'}])
    expect(result.current.loginHandleName).toBe('Username')
    expect(result.current.loginLogoUrl).toBe('https://example.com/logo.png')
    expect(result.current.loginLogoAlt).toBe('Custom Alt Text')
    expect(result.current.bodyBgColor).toBe('#ffffff')
    expect(result.current.bodyBgImage).toBe('https://example.com/bg.png')
    expect(result.current.isPreviewMode).toBe(true)
  })

  it('returns undefined for missing attributes', () => {
    createMockContainer(null, null, null, null, null, null, null)
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toBeUndefined()
    expect(result.current.loginHandleName).toBeUndefined()
    expect(result.current.loginLogoUrl).toBeUndefined()
    expect(result.current.loginLogoAlt).toBeUndefined()
    expect(result.current.bodyBgColor).toBeUndefined()
    expect(result.current.bodyBgImage).toBeUndefined()
    expect(result.current.isPreviewMode).toBeUndefined()
  })

  it('returns undefined for empty string attributes', () => {
    createMockContainer('', '', '', '', '', '', '')
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toBeUndefined()
    expect(result.current.loginHandleName).toBeUndefined()
    expect(result.current.loginLogoUrl).toBeUndefined()
    expect(result.current.loginLogoAlt).toBeUndefined()
    expect(result.current.bodyBgColor).toBeUndefined()
    expect(result.current.bodyBgImage).toBeUndefined()
    expect(result.current.isPreviewMode).toBeUndefined()
  })

  it('handles invalid JSON in data-auth-providers gracefully', () => {
    const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
    createMockContainer(
      'invalid JSON',
      'Username',
      'https://example.com/logo.png',
      'Custom Alt Text',
      '#ffffff',
      'https://example.com/bg.png',
      'true'
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.authProviders).toBeUndefined()
    expect(result.current.loginHandleName).toBe('Username')
    expect(result.current.loginLogoUrl).toBe('https://example.com/logo.png')
    expect(result.current.loginLogoAlt).toBe('Custom Alt Text')
    expect(result.current.bodyBgColor).toBe('#ffffff')
    expect(result.current.bodyBgImage).toBe('https://example.com/bg.png')
    expect(result.current.isPreviewMode).toBe(true)
    // eslint-disable-next-line no-console
    expect(console.error).toHaveBeenCalledWith(
      expect.stringContaining('Failed to parse data-auth-providers'),
      expect.any(SyntaxError)
    )
    consoleErrorMock.mockRestore()
  })

  it('returns false for isPreviewMode when set to "false"', () => {
    createMockContainer(null, null, null, null, null, null, 'false')
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.isPreviewMode).toBe(false)
  })
})

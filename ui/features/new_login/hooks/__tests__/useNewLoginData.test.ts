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
  enableCourseCatalog: string | null,
  authProviders: string | null,
  loginHandleName: string | null,
  loginLogoUrl: string | null,
  loginLogoText: string | null,
  bodyBgColor: string | null,
  bodyBgImage: string | null,
  isPreviewMode: string | null,
  selfRegistrationType: string | null,
  recaptchaKey: string | null,
  fftRegistrationUrl: string | null,
  termsRequired: string | null,
  termsOfUseUrl: string | null,
  privacyPolicyUrl: string | null,
  requireEmail: string | null,
  passwordPolicy: string | null
) => {
  const container = document.createElement('div')
  container.id = 'new_login_data'
  if (enableCourseCatalog !== null) {
    container.setAttribute('data-enable-course-catalog', enableCourseCatalog)
  }
  if (authProviders !== null) {
    container.setAttribute('data-auth-providers', authProviders)
  }
  if (loginHandleName !== null) {
    container.setAttribute('data-login-handle-name', loginHandleName)
  }
  if (loginLogoUrl !== null) {
    container.setAttribute('data-login-logo-url', loginLogoUrl)
  }
  if (loginLogoText !== null) {
    container.setAttribute('data-login-logo-text', loginLogoText)
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
  if (selfRegistrationType !== null) {
    container.setAttribute('data-self-registration-type', selfRegistrationType)
  }
  if (recaptchaKey !== null) {
    container.setAttribute('data-recaptcha-key', recaptchaKey)
  }
  if (fftRegistrationUrl !== null) {
    container.setAttribute('data-fft-registration-url', fftRegistrationUrl)
  }
  if (termsRequired !== null) {
    container.setAttribute('data-terms-required', termsRequired)
  }
  if (termsOfUseUrl !== null) {
    container.setAttribute('data-terms-of-use-url', termsOfUseUrl)
  }
  if (privacyPolicyUrl !== null) {
    container.setAttribute('data-privacy-policy-url', privacyPolicyUrl)
  }
  if (requireEmail !== null) {
    container.setAttribute('data-require-email', requireEmail)
  }
  if (passwordPolicy !== null) {
    container.setAttribute('data-password-policy', passwordPolicy)
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

  it('returns default undefined values when container is not present', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.data).toEqual({
      enableCourseCatalog: undefined,
      authProviders: undefined,
      loginHandleName: undefined,
      loginLogoUrl: undefined,
      loginLogoText: undefined,
      bodyBgColor: undefined,
      bodyBgImage: undefined,
      isPreviewMode: undefined,
      selfRegistrationType: undefined,
      recaptchaKey: undefined,
      fftRegistrationUrl: undefined,
      termsRequired: undefined,
      termsOfUseUrl: undefined,
      privacyPolicyUrl: undefined,
      requireEmail: undefined,
      passwordPolicy: undefined,
    })
  })

  it('returns parsed values from the container when attributes are present', () => {
    createMockContainer(
      'true',
      JSON.stringify([{id: '1', name: 'Google', auth_type: 'google'}]),
      'Username',
      'https://example.com/logo.png',
      'Custom Alt Text',
      '#ffffff',
      'https://example.com/bg.png',
      'true',
      'all',
      'recaptcha_key_value',
      'https://example.com/register',
      'true',
      'https://example.com/terms-of-use',
      'https://example.com/privacy',
      'true',
      JSON.stringify({
        minimum_character_length: 8,
        maximum_login_attempts: 10,
        allow_login_suspension: 'false',
        require_number_characters: 'false',
        require_symbol_characters: 'false',
        common_passwords_folder_id: '1234',
      })
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.data).toEqual({
      enableCourseCatalog: true,
      authProviders: [{id: '1', name: 'Google', auth_type: 'google'}],
      loginHandleName: 'Username',
      loginLogoUrl: 'https://example.com/logo.png',
      loginLogoText: 'Custom Alt Text',
      bodyBgColor: '#ffffff',
      bodyBgImage: 'https://example.com/bg.png',
      isPreviewMode: true,
      selfRegistrationType: 'all',
      recaptchaKey: 'recaptcha_key_value',
      fftRegistrationUrl: 'https://example.com/register',
      termsRequired: true,
      termsOfUseUrl: 'https://example.com/terms-of-use',
      privacyPolicyUrl: 'https://example.com/privacy',
      requireEmail: true,
      passwordPolicy: {
        minimumCharacterLength: 8,
        requireNumberCharacters: false,
        requireSymbolCharacters: false,
      },
    })
  })

  it('handles invalid JSON in data-auth-providers gracefully', () => {
    const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
    createMockContainer(
      null,
      'invalid JSON',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.data.authProviders).toBeUndefined()
    // eslint-disable-next-line no-console
    expect(console.error).toHaveBeenCalledWith(
      expect.stringContaining('Failed to parse data-auth-providers'),
      expect.any(SyntaxError)
    )
    consoleErrorMock.mockRestore()
  })

  it('returns false for boolean attributes when set to "false"', () => {
    createMockContainer(
      'false',
      null,
      null,
      null,
      null,
      null,
      null,
      'false',
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    )
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.data.enableCourseCatalog).toBe(false)
    expect(result.current.data.isPreviewMode).toBe(false)
  })

  it('returns undefined for empty string attributes', () => {
    createMockContainer('', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '')
    const {result} = renderHook(() => useNewLoginData())
    expect(result.current.data).toEqual({
      enableCourseCatalog: undefined,
      authProviders: undefined,
      loginHandleName: undefined,
      loginLogoUrl: undefined,
      loginLogoText: undefined,
      bodyBgColor: undefined,
      bodyBgImage: undefined,
      isPreviewMode: undefined,
      selfRegistrationType: undefined,
      recaptchaKey: undefined,
      fftRegistrationUrl: undefined,
      termsRequired: undefined,
      termsOfUseUrl: undefined,
      privacyPolicyUrl: undefined,
      requireEmail: undefined,
      passwordPolicy: undefined,
    })
  })
})

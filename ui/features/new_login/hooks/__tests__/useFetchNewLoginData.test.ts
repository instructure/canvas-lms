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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {useFetchNewLoginData} from '..'

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
  termsRequired: string | null,
  termsOfUseUrl: string | null,
  privacyPolicyUrl: string | null,
  requireEmail: string | null,
  passwordPolicy: string | null,
  forgotPasswordUrl: string | null,
  invalidLoginFaqUrl: string | null,
  helpLink: string | null,
  requireAup: string | null,
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
  if (forgotPasswordUrl !== null) {
    container.setAttribute('data-forgot-password-url', forgotPasswordUrl)
  }
  if (invalidLoginFaqUrl !== null) {
    container.setAttribute('data-invalid-login-faq-url', invalidLoginFaqUrl)
  }
  if (helpLink !== null) {
    container.setAttribute('data-help-link', helpLink)
  }
  if (requireAup !== null) {
    container.setAttribute('data-require-aup', requireAup)
  }
  document.body.appendChild(container)
}

describe('useFetchNewLoginData', () => {
  afterEach(() => {
    const container = document.getElementById('new_login_data')
    if (container) {
      container.remove()
    }
  })

  it('mounts without crashing', () => {
    const {result} = renderHook(() => useFetchNewLoginData())
    expect(result.current).toBeDefined()
  })

  it('ensures the attributes in useFetchNewLoginData match those in createMockContainer', async () => {
    createMockContainer(
      '', // enableCourseCatalog
      '', // authProviders
      '', // loginHandleName
      '', // loginLogoUrl
      '', // loginLogoText
      '', // bodyBgColor
      '', // bodyBgImage
      '', // isPreviewMode
      '', // selfRegistrationType
      '', // recaptchaKey
      '', // termsRequired
      '', // termsOfUseUrl
      '', // privacyPolicyUrl
      '', // requireEmail
      '', // passwordPolicy
      '', // forgotPasswordUrl
      '', // invalidLoginFaqUrl
      '', // helpLink
      '', // requireAup
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    await waitFor(() => {
      const hookAttributes = Object.keys(result.current.data)
      const expectedAttributes = [
        'enableCourseCatalog',
        'authProviders',
        'loginHandleName',
        'loginLogoUrl',
        'loginLogoText',
        'bodyBgColor',
        'bodyBgImage',
        'isPreviewMode',
        'selfRegistrationType',
        'recaptchaKey',
        'termsRequired',
        'termsOfUseUrl',
        'privacyPolicyUrl',
        'requireEmail',
        'passwordPolicy',
        'forgotPasswordUrl',
        'invalidLoginFaqUrl',
        'helpLink',
        'requireAup',
      ]
      expect(hookAttributes.sort()).toEqual(expectedAttributes.sort())
    })
  })

  it('returns default undefined values when container is not present', () => {
    const {result} = renderHook(() => useFetchNewLoginData())
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
      termsRequired: undefined,
      termsOfUseUrl: undefined,
      privacyPolicyUrl: undefined,
      requireEmail: undefined,
      passwordPolicy: undefined,
      forgotPasswordUrl: undefined,
      invalidLoginFaqUrl: undefined,
      helpLink: undefined,
      requireAup: undefined,
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
      'true',
      'https://example.com/terms-of-use',
      'https://example.com/privacy',
      'true',
      JSON.stringify({
        minimum_character_length: 8,
        require_number_characters: 'false',
        require_symbol_characters: 'false',
      }),
      'https://example.com/password-reset',
      'https://example.com/faq',
      JSON.stringify({
        text: 'Help Center',
        trackCategory: 'login',
        trackLabel: 'help',
      }),
      'true',
    )
    const {result} = renderHook(() => useFetchNewLoginData())
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
      termsRequired: true,
      termsOfUseUrl: 'https://example.com/terms-of-use',
      privacyPolicyUrl: 'https://example.com/privacy',
      requireEmail: true,
      passwordPolicy: {
        minimumCharacterLength: 8,
        requireNumberCharacters: false,
        requireSymbolCharacters: false,
      },
      forgotPasswordUrl: 'https://example.com/password-reset',
      invalidLoginFaqUrl: 'https://example.com/faq',
      helpLink: {
        text: 'Help Center',
        trackCategory: 'login',
        trackLabel: 'help',
      },
      requireAup: true,
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
      null,
      null,
      null,
      null,
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    expect(result.current.data.authProviders).toBeUndefined()
    expect(console.error).toHaveBeenCalledWith(
      expect.stringContaining('Failed to parse data-auth-providers'),
      expect.any(SyntaxError),
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
      'false',
      null,
      null,
      null,
      null,
      'false',
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    expect(result.current.data.enableCourseCatalog).toBe(false)
    expect(result.current.data.isPreviewMode).toBe(false)
    expect(result.current.data.requireEmail).toBe(false)
    expect(result.current.data.requireAup).toBe(false)
  })

  it('returns undefined for empty string attributes', () => {
    createMockContainer('', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '')
    const {result} = renderHook(() => useFetchNewLoginData())
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
      termsRequired: undefined,
      termsOfUseUrl: undefined,
      privacyPolicyUrl: undefined,
      requireEmail: undefined,
      passwordPolicy: undefined,
      forgotPasswordUrl: undefined,
      invalidLoginFaqUrl: undefined,
      helpLink: undefined,
      requireAup: undefined,
    })
  })

  it('returns empty structures for present but empty object-like attributes', () => {
    createMockContainer(
      null,
      JSON.stringify({}), // authProviders
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
      JSON.stringify({}), // passwordPolicy
      null,
      null,
      null,
      JSON.stringify({}), // helpLink
      null,
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    const data = result.current.data
    expect(data.passwordPolicy).toBeUndefined()
    expect(data.authProviders).toEqual({})
    expect(data.helpLink).toEqual({text: '', trackCategory: '', trackLabel: ''})
  })

  it('returns undefined for object-like attributes that are missing from the DOM', () => {
    createMockContainer(
      null,
      null, // authProviders
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
      null, // passwordPolicy
      null,
      null,
      null,
      null, // helpLink
      null,
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    const data = result.current.data
    expect(data.passwordPolicy).toBeUndefined()
    expect(data.authProviders).toBeUndefined()
    expect(data.helpLink).toBeUndefined()
  })

  // returns raw values; escaping/sanitizing is the responsibility of the rendering layer
  it('returns potentially unsafe-looking strings without decoding or sanitizing', () => {
    const xssString = '" onmouseover="alert(\'xss\')'
    const xssScript = '<script>alert("xss")</script>'
    const weirdUnicode = 'string with 𝒲𝒺𝒾𝓇𝒹 chars 💣'
    const helpLink = {
      text: xssScript,
      trackCategory: 'category',
      trackLabel: 'label',
    }
    const container = document.createElement('div')
    container.id = 'new_login_data'
    container.setAttribute('data-login-handle-name', xssString)
    container.setAttribute('data-login-logo-text', `${xssScript} ${weirdUnicode}`)
    container.setAttribute('data-help-link', JSON.stringify(helpLink))
    document.body.appendChild(container)
    const {result} = renderHook(() => useFetchNewLoginData())
    expect(result.current.data.loginHandleName).toBe(xssString)
    expect(result.current.data.loginLogoText).toBe(`${xssScript} ${weirdUnicode}`)
    expect(result.current.data.helpLink).toEqual(helpLink)
  })
})

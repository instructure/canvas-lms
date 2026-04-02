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
  customMessageLogin?: string | null,
  customMessageRegistration?: string | null,
  customMessageRegistrationParent?: string | null,
  freeForTeacherRegistrationUrl?: string | null,
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
  if (customMessageLogin !== undefined && customMessageLogin !== null) {
    container.setAttribute('data-custom-message-login', customMessageLogin)
  }
  if (customMessageRegistration !== undefined && customMessageRegistration !== null) {
    container.setAttribute('data-custom-message-registration', customMessageRegistration)
  }
  if (customMessageRegistrationParent !== undefined && customMessageRegistrationParent !== null) {
    container.setAttribute(
      'data-custom-message-registration-parent',
      customMessageRegistrationParent,
    )
  }
  if (freeForTeacherRegistrationUrl !== undefined && freeForTeacherRegistrationUrl !== null) {
    container.setAttribute('data-free-for-teacher-registration-url', freeForTeacherRegistrationUrl)
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
      '', // customMessageLogin
      '', // customMessageRegistration
      '', // customMessageRegistrationParent
      '', // freeForTeacherRegistrationUrl
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
        'customMessageLogin',
        'customMessageRegistration',
        'customMessageRegistrationParent',
        'freeForTeacherRegistrationUrl',
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
      customMessageLogin: undefined,
      customMessageRegistration: undefined,
      customMessageRegistrationParent: undefined,
      freeForTeacherRegistrationUrl: undefined,
    })
  })

  it('returns parsed values from the container when attributes are present', () => {
    createMockContainer(
      'true', // enableCourseCatalog
      JSON.stringify([{id: '1', name: 'Google', auth_type: 'google'}]), // authProviders
      'Username', // loginHandleName
      'https://example.com/logo.png', // loginLogoUrl
      'Custom Alt Text', // loginLogoText
      '#ffffff', // bodyBgColor
      'https://example.com/bg.png', // bodyBgImage
      'true', // isPreviewMode
      'all', // selfRegistrationType
      'recaptcha_key_value', // recaptchaKey
      'true', // termsRequired
      '/acceptable_use_policy', // termsOfUseUrl
      'https://example.com/privacy', // privacyPolicyUrl
      'true', // requireEmail
      JSON.stringify({
        minimum_character_length: 8,
        require_number_characters: 'false',
        require_symbol_characters: 'false',
      }), // passwordPolicy
      'https://example.com/password-reset', // forgotPasswordUrl
      'https://example.com/faq', // invalidLoginFaqUrl
      JSON.stringify({
        text: 'Help Center',
        trackCategory: 'login',
        trackLabel: 'help',
      }), // helpLink
      'true', // requireAup
      'Welcome to our platform!', // customMessageLogin
      'Register to get started!', // customMessageRegistration
      'Please fill out the registration form below.', // customMessageRegistrationParent
      'https://fft.example.com/register', // freeForTeacherRegistrationUrl
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
      termsOfUseUrl: '/acceptable_use_policy',
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
      customMessageLogin: 'Welcome to our platform!',
      customMessageRegistration: 'Register to get started!',
      customMessageRegistrationParent: 'Please fill out the registration form below.',
      freeForTeacherRegistrationUrl: 'https://fft.example.com/register',
    })
  })

  it('handles invalid JSON in data-auth-providers gracefully', () => {
    const consoleErrorMock = vi.spyOn(console, 'error').mockImplementation(() => {})
    createMockContainer(
      null, // enableCourseCatalog
      'invalid JSON', // authProviders
      null, // loginHandleName
      null, // loginLogoUrl
      null, // loginLogoText
      null, // bodyBgColor
      null, // bodyBgImage
      null, // isPreviewMode
      null, // selfRegistrationType
      null, // recaptchaKey
      null, // termsRequired
      null, // termsOfUseUrl
      null, // privacyPolicyUrl
      null, // requireEmail
      null, // passwordPolicy
      null, // forgotPasswordUrl
      null, // invalidLoginFaqUrl
      null, // helpLink
      null, // requireAup
      null, // customMessageLogin
      null, // customMessageRegistration
      null, // customMessageRegistrationParent
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
      'false', // enableCourseCatalog
      null, // authProviders
      null, // loginHandleName
      null, // loginLogoUrl
      null, // loginLogoText
      null, // bodyBgColor
      null, // bodyBgImage
      'false', // isPreviewMode
      null, // selfRegistrationType
      null, // recaptchaKey
      null, // termsRequired
      null, // termsOfUseUrl
      null, // privacyPolicyUrl
      'false', // requireEmail
      null, // passwordPolicy
      null, // forgotPasswordUrl
      null, // invalidLoginFaqUrl
      null, // helpLink
      'false', // requireAup
      null, // customMessageLogin
      null, // customMessageRegistration
      null, // customMessageRegistrationParent
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    expect(result.current.data.enableCourseCatalog).toBe(false)
    expect(result.current.data.isPreviewMode).toBe(false)
    expect(result.current.data.requireEmail).toBe(false)
    expect(result.current.data.requireAup).toBe(false)
  })

  it('returns undefined for empty string attributes', () => {
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
      '', // customMessageLogin
      '', // customMessageRegistration
      '', // customMessageRegistrationParent
      '', // freeForTeacherRegistrationUrl
    )
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
      customMessageLogin: undefined,
      customMessageRegistration: undefined,
      customMessageRegistrationParent: undefined,
      freeForTeacherRegistrationUrl: undefined,
    })
  })

  it('returns empty structures for present but empty object-like attributes', () => {
    createMockContainer(
      null, // enableCourseCatalog
      JSON.stringify({}), // authProviders
      null, // loginHandleName
      null, // loginLogoUrl
      null, // loginLogoText
      null, // bodyBgColor
      null, // bodyBgImage
      null, // isPreviewMode
      null, // selfRegistrationType
      null, // recaptchaKey
      null, // termsRequired
      null, // termsOfUseUrl
      null, // privacyPolicyUrl
      null, // requireEmail
      JSON.stringify({}), // passwordPolicy
      null, // forgotPasswordUrl
      null, // invalidLoginFaqUrl
      JSON.stringify({}), // helpLink
      null, // requireAup
      null, // customMessageLogin
      null, // customMessageRegistration
      null, // customMessageRegistrationParent
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    const data = result.current.data
    expect(data.passwordPolicy).toEqual({
      minimumCharacterLength: undefined,
      requireNumberCharacters: false,
      requireSymbolCharacters: false,
    })
    expect(data.authProviders).toEqual({})
    expect(data.helpLink).toEqual({text: '', trackCategory: '', trackLabel: ''})
  })

  it('returns undefined for object-like attributes that are missing from the DOM', () => {
    createMockContainer(
      null, // enableCourseCatalog
      null, // authProviders
      null, // loginHandleName
      null, // loginLogoUrl
      null, // loginLogoText
      null, // bodyBgColor
      null, // bodyBgImage
      null, // isPreviewMode
      null, // selfRegistrationType
      null, // recaptchaKey
      null, // termsRequired
      null, // termsOfUseUrl
      null, // privacyPolicyUrl
      null, // requireEmail
      null, // passwordPolicy
      null, // forgotPasswordUrl
      null, // invalidLoginFaqUrl
      null, // helpLink
      null, // requireAup
      null, // customMessageLogin
      null, // customMessageRegistration
      null, // customMessageRegistrationParent
    )
    const {result} = renderHook(() => useFetchNewLoginData())
    const data = result.current.data
    expect(data.passwordPolicy).toBeUndefined()
    expect(data.authProviders).toBeUndefined()
    expect(data.helpLink).toBeUndefined()
  })

  describe('escaping and sanitizing responsibility', () => {
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

    it('returns potentially unsafe-looking custom message strings without decoding or sanitizing', () => {
      const xssStrings = [
        `" onclick="alert('xss')`,
        `" onmouseover="alert(1)`,
        `&quot;onclick&quot;=&quot;alert(1)&quot;`,
        `<script>alert('xss')</script>`,
        `<img src=x onerror=alert(1)>`,
        '`alert(1)`',
        'javascript:alert(1)',
        'test',
        '<img src=x onerror=alert(1)>',
      ]
      createMockContainer(
        null, // enableCourseCatalog
        null, // authProviders
        null, // loginHandleName
        null, // loginLogoUrl
        null, // loginLogoText
        null, // bodyBgColor
        null, // bodyBgImage
        null, // isPreviewMode
        null, // selfRegistrationType
        null, // recaptchaKey
        null, // termsRequired
        null, // termsOfUseUrl
        null, // privacyPolicyUrl
        null, // requireEmail
        null, // passwordPolicy
        null, // forgotPasswordUrl
        null, // invalidLoginFaqUrl
        null, // helpLink
        null, // requireAup
        xssStrings[0], // customMessageLogin
        xssStrings[2], // customMessageRegistration
        xssStrings[3], // customMessageRegistrationParent
      )
      const {result} = renderHook(() => useFetchNewLoginData())
      expect(result.current.data.customMessageLogin).toBe(xssStrings[0])
      expect(result.current.data.customMessageRegistration).toBe(xssStrings[2])
      expect(result.current.data.customMessageRegistrationParent).toBe(xssStrings[3])
    })
  })
})

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

import {render, screen} from '@testing-library/react'
import React from 'react'
import '@testing-library/jest-dom'
import {renderHook} from '@testing-library/react-hooks'
import {NewLoginDataProvider, useNewLoginData} from '..'

const mockUseFetchNewLoginData = jest.fn()

jest.mock('../../hooks/useFetchNewLoginData', () => {
  return {
    useFetchNewLoginData: jest.fn(() => mockUseFetchNewLoginData()),
  }
})

const TestComponent = () => {
  const context = useNewLoginData()
  return (
    <div>
      <span data-testid="isDataLoading">{context.isDataLoading.toString()}</span>
      <span data-testid="enableCourseCatalog">{context.enableCourseCatalog?.toString()}</span>
      <span data-testid="authProviders">
        {context.authProviders?.map(provider => provider.auth_type).join(', ') || ''}
      </span>
      <span data-testid="loginHandleName">{context.loginHandleName || ''}</span>
      <span data-testid="loginLogoUrl">{context.loginLogoUrl || ''}</span>
      <span data-testid="loginLogoText">{context.loginLogoText || ''}</span>
      <span data-testid="bodyBgColor">{context.bodyBgColor || ''}</span>
      <span data-testid="bodyBgImage">{context.bodyBgImage || ''}</span>
      <span data-testid="isPreviewMode">{context.isPreviewMode?.toString()}</span>
      <span data-testid="selfRegistrationType">{context.selfRegistrationType || ''}</span>
      <span data-testid="recaptchaKey">{context.recaptchaKey || ''}</span>
      <span data-testid="termsRequired">{context.termsRequired?.toString()}</span>
      <span data-testid="termsOfUseUrl">{context.termsOfUseUrl || ''}</span>
      <span data-testid="privacyPolicyUrl">{context.privacyPolicyUrl || ''}</span>
      <span data-testid="requireEmail">{context.requireEmail?.toString()}</span>
      <span data-testid="passwordPolicy">{JSON.stringify(context.passwordPolicy) || ''}</span>
      <span data-testid="forgotPasswordUrl">{context.forgotPasswordUrl || ''}</span>
      <span data-testid="invalidLoginFaqUrl">{context.invalidLoginFaqUrl || ''}</span>
      <span data-testid="helpLink">{JSON.stringify(context.helpLink) || ''}</span>
      <span data-testid="requireAup">{context.requireAup || ''}</span>
    </div>
  )
}

describe('NewLoginDataContext', () => {
  let originalConsoleError: typeof console.error

  beforeEach(() => {
    jest.clearAllMocks()
    originalConsoleError = console.error
  })

  afterEach(() => {
    console.error = originalConsoleError
  })

  it('ensures NewLoginDataContext stays in sync with useFetchNewLoginData', () => {
    const expectedKeys = [
      'isDataLoading',
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
    mockUseFetchNewLoginData.mockReturnValue({
      isDataLoading: false,
      data: {},
    })
    const {result} = renderHook(() => useNewLoginData(), {
      wrapper: NewLoginDataProvider,
    })
    expect(Object.keys(result.current).sort()).toEqual(expectedKeys.sort())
  })

  it('renders loading state correctly', () => {
    mockUseFetchNewLoginData.mockReturnValue({
      isDataLoading: true,
      data: {},
    })
    render(
      <NewLoginDataProvider>
        <TestComponent />
      </NewLoginDataProvider>,
    )
    expect(screen.getByTestId('isDataLoading')).toHaveTextContent('true')
    expect(screen.getByTestId('enableCourseCatalog')).toBeEmptyDOMElement()
    expect(screen.getByTestId('authProviders')).toBeEmptyDOMElement()
  })

  it('provides data from useFetchNewLoginData hook correctly', () => {
    mockUseFetchNewLoginData.mockReturnValue({
      isDataLoading: false,
      data: {
        enableCourseCatalog: true,
        authProviders: [
          {id: 1, auth_type: 'Google'},
          {id: 2, auth_type: 'Microsoft'},
        ],
        loginHandleName: 'exampleLoginHandle',
        loginLogoUrl: 'https://example.com/logo.svg',
        loginLogoText: 'Welcome to Canvas',
        bodyBgColor: '#ffffff',
        bodyBgImage: 'https://example.com/bg.jpg',
        isPreviewMode: true,
        selfRegistrationType: 'Open',
        recaptchaKey: '12345',
        termsRequired: true,
        termsOfUseUrl: 'https://example.com/terms',
        privacyPolicyUrl: 'https://example.com/privacy',
        requireEmail: false,
        passwordPolicy: {minLength: 8, requiresNumbers: true},
        forgotPasswordUrl: 'https://example.com/password-reset',
        invalidLoginFaqUrl: 'https://example.com/faq',
        helpLink: {url: 'https://example.com/help', label: 'Need Help?'},
        requireAup: 'true',
      },
    })
    render(
      <NewLoginDataProvider>
        <TestComponent />
      </NewLoginDataProvider>,
    )
    expect(screen.getByTestId('isDataLoading')).toHaveTextContent('false')
    expect(screen.getByTestId('enableCourseCatalog')).toHaveTextContent('true')
    expect(screen.getByTestId('authProviders')).toHaveTextContent('Google, Microsoft')
    expect(screen.getByTestId('loginHandleName')).toHaveTextContent('exampleLoginHandle')
    expect(screen.getByTestId('loginLogoUrl')).toHaveTextContent('https://example.com/logo.svg')
    expect(screen.getByTestId('loginLogoText')).toHaveTextContent('Welcome to Canvas')
    expect(screen.getByTestId('bodyBgColor')).toHaveTextContent('#ffffff')
    expect(screen.getByTestId('bodyBgImage')).toHaveTextContent('https://example.com/bg.jpg')
    expect(screen.getByTestId('isPreviewMode')).toHaveTextContent('true')
    expect(screen.getByTestId('selfRegistrationType')).toHaveTextContent('Open')
    expect(screen.getByTestId('recaptchaKey')).toHaveTextContent('12345')
    expect(screen.getByTestId('termsRequired')).toHaveTextContent('true')
    expect(screen.getByTestId('termsOfUseUrl')).toHaveTextContent('https://example.com/terms')
    expect(screen.getByTestId('privacyPolicyUrl')).toHaveTextContent('https://example.com/privacy')
    expect(screen.getByTestId('requireEmail')).toHaveTextContent('false')
    expect(screen.getByTestId('passwordPolicy')).toHaveTextContent(
      JSON.stringify({minLength: 8, requiresNumbers: true}),
    )
    expect(screen.getByTestId('forgotPasswordUrl')).toHaveTextContent(
      'https://example.com/password-reset',
    )
    expect(screen.getByTestId('invalidLoginFaqUrl')).toHaveTextContent('https://example.com/faq')
    expect(screen.getByTestId('helpLink')).toHaveTextContent(
      JSON.stringify({url: 'https://example.com/help', label: 'Need Help?'}),
    )
    expect(screen.getByTestId('requireAup')).toHaveTextContent('true')
  })

  it('handles undefined optional values gracefully', () => {
    mockUseFetchNewLoginData.mockReturnValue({
      isDataLoading: false,
      data: {},
    })
    render(
      <NewLoginDataProvider>
        <TestComponent />
      </NewLoginDataProvider>,
    )
    expect(screen.getByTestId('enableCourseCatalog')).toBeEmptyDOMElement()
    expect(screen.getByTestId('authProviders')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginHandleName')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginLogoUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginLogoText')).toBeEmptyDOMElement()
    expect(screen.getByTestId('bodyBgColor')).toBeEmptyDOMElement()
    expect(screen.getByTestId('bodyBgImage')).toBeEmptyDOMElement()
    expect(screen.getByTestId('isPreviewMode')).toBeEmptyDOMElement()
    expect(screen.getByTestId('selfRegistrationType')).toBeEmptyDOMElement()
    expect(screen.getByTestId('recaptchaKey')).toBeEmptyDOMElement()
    expect(screen.getByTestId('termsRequired')).toBeEmptyDOMElement()
    expect(screen.getByTestId('termsOfUseUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('privacyPolicyUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('requireEmail')).toBeEmptyDOMElement()
    expect(screen.getByTestId('passwordPolicy')).toBeEmptyDOMElement()
    expect(screen.getByTestId('forgotPasswordUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('invalidLoginFaqUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('helpLink')).toBeEmptyDOMElement()
    expect(screen.getByTestId('requireAup')).toBeEmptyDOMElement()
  })

  it('throws an error if useNewLoginData is used outside NewLoginDataProvider', () => {
    const {result} = renderHook(() => useNewLoginData())
    expect(result.error).toEqual(
      new Error('useNewLoginData must be used within a NewLoginDataProvider'),
    )
  })
})

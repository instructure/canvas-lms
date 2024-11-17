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

import React, {useEffect} from 'react'
import {act, render, screen} from '@testing-library/react'
import '@testing-library/jest-dom'
import {NewLoginProvider, useNewLogin} from '../NewLoginContext'
import type {AuthProvider} from '../../types'

jest.mock('../../hooks/useNewLoginData', () => ({
  useNewLoginData: () => ({
    enableCourseCatalog: true,
    authProviders: [
      {id: 1, auth_type: 'Google'},
      {id: 2, auth_type: 'Microsoft'},
    ] as AuthProvider[],
    loginHandleName: 'exampleLoginHandle',
    loginLogoUrl: 'login/canvas-logo.svg',
    loginLogoText: 'Canvas by Instructure',
    bodyBgColor: '#ffffff',
    bodyBgImage: 'https://example.com/background.jpg',
    isPreviewMode: true,
  }),
}))

const TestComponent = () => {
  const context = useNewLogin()
  return (
    <div>
      <span data-testid="rememberMe">{context.rememberMe.toString()}</span>
      <span data-testid="isUiActionPending">{context.isUiActionPending.toString()}</span>
      <span data-testid="otpRequired">{context.otpRequired.toString()}</span>
      <span data-testid="showForgotPassword">{context.showForgotPassword.toString()}</span>
      <span data-testid="otpCommunicationChannelId">
        {context.otpCommunicationChannelId || 'null'}
      </span>
      <span data-testid="enableCourseCatalog">{context.enableCourseCatalog?.toString()}</span>
      <span data-testid="authProviders">
        {context.authProviders?.map(provider => provider.auth_type).join(', ')}
      </span>
      <span data-testid="loginHandleName">{context.loginHandleName}</span>
      <span data-testid="loginLogoUrl">{context.loginLogoUrl}</span>
      <span data-testid="loginLogoText">{context.loginLogoText}</span>
      <span data-testid="bodyBgColor">{context.bodyBgColor}</span>
      <span data-testid="bodyBgImage">{context.bodyBgImage}</span>
      <span data-testid="isPreviewMode">{context.isPreviewMode?.toString()}</span>
    </div>
  )
}

describe('NewLoginContext', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders without crashing', () => {
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>
    )
  })

  it('provides initial context values and integrates useNewLoginData hook values correctly', () => {
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>
    )
    expect(screen.getByTestId('rememberMe')).toHaveTextContent('false')
    expect(screen.getByTestId('isUiActionPending')).toHaveTextContent('false')
    expect(screen.getByTestId('otpRequired')).toHaveTextContent('false')
    expect(screen.getByTestId('showForgotPassword')).toHaveTextContent('false')
    expect(screen.getByTestId('otpCommunicationChannelId')).toHaveTextContent('null')
    // values from useNewLoginData hook
    expect(screen.getByTestId('enableCourseCatalog')).toHaveTextContent('true')
    expect(screen.getByTestId('authProviders')).toHaveTextContent('Google, Microsoft')
    expect(screen.getByTestId('loginHandleName')).toHaveTextContent('exampleLoginHandle')
    expect(screen.getByTestId('loginLogoUrl')).toHaveTextContent('login/canvas-logo.svg')
    expect(screen.getByTestId('loginLogoText')).toHaveTextContent('Canvas by Instructure')
    expect(screen.getByTestId('bodyBgColor')).toHaveTextContent('#ffffff')
    expect(screen.getByTestId('bodyBgImage')).toHaveTextContent(
      'https://example.com/background.jpg'
    )
    expect(screen.getByTestId('isPreviewMode')).toHaveTextContent('true')
  })

  it('allows context values to be updated correctly', () => {
    const ConsumerComponent = () => {
      const {
        setRememberMe,
        setIsUiActionPending,
        setOtpRequired,
        setShowForgotPassword,
        setOtpCommunicationChannelId,
      } = useNewLogin()
      useEffect(() => {
        act(() => {
          setRememberMe(true)
          setIsUiActionPending(true)
          setOtpRequired(true)
          setShowForgotPassword(true)
          setOtpCommunicationChannelId('12345')
        })
      }, [
        setRememberMe,
        setIsUiActionPending,
        setOtpRequired,
        setShowForgotPassword,
        setOtpCommunicationChannelId,
      ])
      return <TestComponent />
    }
    render(
      <NewLoginProvider>
        <ConsumerComponent />
      </NewLoginProvider>
    )
    expect(screen.getByTestId('rememberMe')).toHaveTextContent('true')
    expect(screen.getByTestId('isUiActionPending')).toHaveTextContent('true')
    expect(screen.getByTestId('otpRequired')).toHaveTextContent('true')
    expect(screen.getByTestId('showForgotPassword')).toHaveTextContent('true')
    expect(screen.getByTestId('otpCommunicationChannelId')).toHaveTextContent('12345')
  })

  it('handles optional values being undefined', () => {
    jest.spyOn(require('../../hooks/useNewLoginData'), 'useNewLoginData').mockReturnValue({
      enableCourseCatalog: undefined,
      authProviders: undefined,
      loginHandleName: undefined,
      loginLogoUrl: undefined,
      loginLogoText: undefined,
      bodyBgColor: undefined,
      bodyBgImage: undefined,
      isPreviewMode: undefined,
    })
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>
    )
    expect(screen.getByTestId('enableCourseCatalog')).toBeEmptyDOMElement()
    expect(screen.getByTestId('authProviders')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginHandleName')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginLogoUrl')).toBeEmptyDOMElement()
    expect(screen.getByTestId('loginLogoText')).toBeEmptyDOMElement()
    expect(screen.getByTestId('bodyBgColor')).toBeEmptyDOMElement()
    expect(screen.getByTestId('bodyBgImage')).toBeEmptyDOMElement()
    expect(screen.getByTestId('isPreviewMode')).toBeEmptyDOMElement()
  })
})

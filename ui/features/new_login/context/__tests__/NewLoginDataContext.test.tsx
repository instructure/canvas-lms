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
      <span data-testid="forgotPasswordUrl">{context.forgotPasswordUrl || ''}</span>
    </div>
  )
}

describe('NewLoginDataContext', () => {
  beforeEach(() => {
    jest.clearAllMocks()
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
        loginLogoText: 'Welcome to Canvas.',
        bodyBgColor: '#ffffff',
        bodyBgImage: 'https://example.com/bg.jpg',
        isPreviewMode: true,
        forgotPasswordUrl: 'https://example.com/password-reset',
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
    expect(screen.getByTestId('loginLogoText')).toHaveTextContent('Welcome to Canvas.')
    expect(screen.getByTestId('bodyBgColor')).toHaveTextContent('#ffffff')
    expect(screen.getByTestId('bodyBgImage')).toHaveTextContent('https://example.com/bg.jpg')
    expect(screen.getByTestId('isPreviewMode')).toHaveTextContent('true')
    expect(screen.getByTestId('forgotPasswordUrl')).toHaveTextContent(
      'https://example.com/password-reset',
    )
  })

  it('handles undefined optional values gracefully', () => {
    mockUseFetchNewLoginData.mockReturnValue({
      isDataLoading: false,
      data: {
        enableCourseCatalog: undefined,
        authProviders: undefined,
        loginHandleName: undefined,
        loginLogoUrl: undefined,
        loginLogoText: undefined,
        bodyBgColor: undefined,
        bodyBgImage: undefined,
        isPreviewMode: undefined,
        forgotPasswordUrl: undefined,
      },
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
    expect(screen.getByTestId('forgotPasswordUrl')).toBeEmptyDOMElement()
  })

  it('throws an error if useNewLoginData is used outside NewLoginDataProvider', () => {
    const OriginalConsoleError = console.error
    console.error = jest.fn()
    const renderOutsideProvider = () => {
      render(<TestComponent />)
    }
    expect(renderOutsideProvider).toThrow(
      'useNewLoginData must be used within a NewLoginDataProvider',
    )
    console.error = OriginalConsoleError
  })
})

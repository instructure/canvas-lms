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

import {act, cleanup, render, screen} from '@testing-library/react'
import React, {useEffect} from 'react'
import {NewLoginProvider, useNewLogin} from '..'

class ErrorBoundary extends React.Component<
  {children: React.ReactNode; onError: (error: Error) => void},
  {hasError: boolean}
> {
  constructor(props: {children: React.ReactNode; onError: (error: Error) => void}) {
    super(props)
    this.state = {hasError: false}
  }

  static getDerivedStateFromError() {
    return {hasError: true}
  }

  componentDidCatch(error: Error) {
    this.props.onError(error)
  }

  render() {
    if (this.state.hasError) {
      return null
    }
    return this.props.children
  }
}

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
    </div>
  )
}

afterEach(() => {
  cleanup()
})

describe('NewLoginContext', () => {
  it('renders without crashing', () => {
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>,
    )
  })

  it('provides initial context values', () => {
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>,
    )
    expect(screen.getByTestId('rememberMe')).toHaveTextContent('false')
    expect(screen.getByTestId('isUiActionPending')).toHaveTextContent('false')
    expect(screen.getByTestId('otpRequired')).toHaveTextContent('false')
    expect(screen.getByTestId('showForgotPassword')).toHaveTextContent('false')
    expect(screen.getByTestId('otpCommunicationChannelId')).toHaveTextContent('null')
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
      </NewLoginProvider>,
    )
    expect(screen.getByTestId('rememberMe')).toHaveTextContent('true')
    expect(screen.getByTestId('isUiActionPending')).toHaveTextContent('true')
    expect(screen.getByTestId('otpRequired')).toHaveTextContent('true')
    expect(screen.getByTestId('showForgotPassword')).toHaveTextContent('true')
    expect(screen.getByTestId('otpCommunicationChannelId')).toHaveTextContent('12345')
  })

  it('handles default values correctly when no updates are made', () => {
    render(
      <NewLoginProvider>
        <TestComponent />
      </NewLoginProvider>,
    )
    expect(screen.getByTestId('rememberMe')).toHaveTextContent('false')
    expect(screen.getByTestId('isUiActionPending')).toHaveTextContent('false')
    expect(screen.getByTestId('otpRequired')).toHaveTextContent('false')
    expect(screen.getByTestId('showForgotPassword')).toHaveTextContent('false')
    expect(screen.getByTestId('otpCommunicationChannelId')).toHaveTextContent('null')
  })

  it('throws an error if useNewLogin is used outside NewLoginProvider', () => {
    // Suppress console errors during error boundary testing
    const originalError = console.error
    const originalWarn = console.warn
    console.error = () => {}
    console.warn = () => {}

    // Also suppress jsdom errors
    const originalOnError = window.onerror
    window.onerror = () => true

    let caughtError: Error | null = null

    render(
      <ErrorBoundary
        onError={(error: Error) => {
          caughtError = error
        }}
      >
        <TestComponent />
      </ErrorBoundary>,
    )

    expect(caughtError!.message).toBe('useNewLogin must be used within a NewLoginProvider')

    // Restore original handlers
    console.error = originalError
    console.warn = originalWarn
    window.onerror = originalOnError
  })
})

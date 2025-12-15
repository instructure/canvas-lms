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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen} from '@testing-library/react'
import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

// Component that throws an error during render
class ThrowsErrorComponent extends React.Component {
  componentDidMount() {
    throw new Error('Test error message for assignments')
  }

  render() {
    return <div>This should not render</div>
  }
}

describe('Assignments Show Student ErrorBoundary', () => {
  let consoleErrorSpy
  let originalError

  beforeEach(() => {
    // Mock console.error to prevent error output in tests
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    // Also suppress window.onerror to prevent JSDOM from logging errors
    originalError = window.onerror
    window.onerror = () => true
  })

  afterEach(() => {
    // Restore console.error after each test
    consoleErrorSpy.mockRestore()

    // Restore window.onerror
    window.onerror = originalError
  })

  describe('with function errorComponent', () => {
    it('passes error information to GenericErrorPage when an error occurs', () => {
      const originalNodeEnv = process.env.NODE_ENV
      process.env.NODE_ENV = 'development'

      render(
        <ErrorBoundary
          errorComponent={({error}) => (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={error.message}
              errorCategory="Assignments 2 Student Error Page"
              errorMessage={error.message}
              stack={error.stack}
            />
          )}
        >
          <ThrowsErrorComponent />
        </ErrorBoundary>,
      )

      // The error message should be visible in development mode
      expect(screen.getByText('Test error message for assignments')).toBeInTheDocument()

      // The error page header should always be rendered
      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
      expect(screen.getByText('Help us improve by telling us what happened')).toBeInTheDocument()

      process.env.NODE_ENV = originalNodeEnv
    })

    it('does not display "No Error Message" when error occurs', () => {
      const originalNodeEnv = process.env.NODE_ENV
      process.env.NODE_ENV = 'development'

      render(
        <ErrorBoundary
          errorComponent={({error}) => (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={error.message}
              errorCategory="Assignments 2 Student Error Page"
              errorMessage={error.message}
              stack={error.stack}
            />
          )}
        >
          <ThrowsErrorComponent />
        </ErrorBoundary>,
      )

      // Should NOT show the default error message
      expect(screen.queryByText('No Error Message')).not.toBeInTheDocument()

      process.env.NODE_ENV = originalNodeEnv
    })
  })

  describe('with static JSX errorComponent (incorrect pattern)', () => {
    it('shows "No Error Message" when error information is not passed', () => {
      const originalNodeEnv = process.env.NODE_ENV
      process.env.NODE_ENV = 'development'

      render(
        <ErrorBoundary
          errorComponent={
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorCategory="Assignments 2 Student Error Page"
            />
          }
        >
          <ThrowsErrorComponent />
        </ErrorBoundary>,
      )

      // When error is not passed, it defaults to "No Error Message"
      expect(screen.getByText('No Error Message')).toBeInTheDocument()

      // The error page header should still be rendered
      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()

      process.env.NODE_ENV = originalNodeEnv
    })
  })

  describe('without errors', () => {
    it('renders children normally when no error occurs', () => {
      render(
        <ErrorBoundary
          errorComponent={({error}) => (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={error.message}
              errorCategory="Assignments 2 Student Error Page"
              errorMessage={error.message}
              stack={error.stack}
            />
          )}
        >
          <div>Normal content</div>
        </ErrorBoundary>,
      )

      expect(screen.getByText('Normal content')).toBeInTheDocument()
      expect(screen.queryByText('Sorry, Something Broke')).not.toBeInTheDocument()
    })
  })
})

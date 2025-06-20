/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ErrorBoundary from '../index'
import GenericErrorPage from '@canvas/generic-error-page'
import {render} from '@testing-library/react'

class ThrowsErrorComponent extends React.Component {
  componentDidMount() {
    throw new Error('Monster Kill')
  }

  render() {
    return <div />
  }
}

const defaultGenericProps = {
  errorCategory: '404',
  imageUrl: 'http://imageUrl',
}

const defaultProps = () => ({
  errorComponent: <GenericErrorPage {...defaultGenericProps} />,
})

describe('ErrorBoundary', () => {
  let consoleErrorSpy: jest.SpyInstance
  let originalError: typeof window.onerror

  beforeEach(() => {
    // Mock console.error to prevent error output in tests
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

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

  test('renders the component', () => {
    const {getByText} = render(
      <ErrorBoundary {...defaultProps()}>
        <div>Making sure this works</div>
      </ErrorBoundary>,
    )
    expect(getByText('Making sure this works')).toBeInTheDocument()
  })

  test('renders the component when error is thrown', () => {
    const {getByText} = render(
      <ErrorBoundary errorComponent={<div>Making sure this does not work</div>}>
        <div>
          <div>Making sure this works</div>
          <ThrowsErrorComponent />
        </div>
      </ErrorBoundary>,
    )
    expect(getByText('Making sure this does not work')).toBeInTheDocument()
    expect(consoleErrorSpy).toHaveBeenCalled()
  })

  test('calls "beforeCapture" when provided', () => {
    const beforeCaptureMock = jest.fn()
    render(
      <ErrorBoundary errorComponent={<></>} beforeCapture={beforeCaptureMock}>
        <ThrowsErrorComponent />
      </ErrorBoundary>,
    )

    expect(beforeCaptureMock).toHaveBeenCalled()
    expect(consoleErrorSpy).toHaveBeenCalled()
  })
})

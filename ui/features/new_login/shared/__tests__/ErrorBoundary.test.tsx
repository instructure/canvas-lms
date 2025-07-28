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

import {render} from '@testing-library/react'
import React from 'react'
import {ErrorBoundary} from '..'

const ProblematicComponent = () => {
  throw new Error('Test error')
}

const renderWithErrorBoundary = (ui: React.ReactNode) =>
  render(<ErrorBoundary fallback={<div>Error occurred</div>}>{ui}</ErrorBoundary>)

describe('ErrorBoundary', () => {
  describe('Functionality', () => {
    it('renders child components when no error is thrown', () => {
      const {getByText} = renderWithErrorBoundary(<div>Test component</div>)
      expect(getByText('Test component')).toBeInTheDocument()
    })

    it('renders multiple children without error', () => {
      const {getByText} = renderWithErrorBoundary(
        <>
          <div>Child 1</div>
          <div>Child 2</div>
        </>,
      )
      expect(getByText('Child 1')).toBeInTheDocument()
      expect(getByText('Child 2')).toBeInTheDocument()
    })
  })

  describe('Error Handling', () => {
    it('renders the fallback UI when an error is thrown', () => {
      const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
      const {getByText} = renderWithErrorBoundary(<ProblematicComponent />)
      expect(getByText('Error occurred')).toBeInTheDocument()
      consoleErrorMock.mockRestore()
    })

    it('logs the error to the console', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      renderWithErrorBoundary(<ProblematicComponent />)
      expect(consoleErrorSpy).toHaveBeenCalled()
      consoleErrorSpy.mockRestore()
    })
  })

  describe('State Management', () => {
    it('resets error state when new children are provided', () => {
      const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {})
      const {rerender, queryByText} = renderWithErrorBoundary(<ProblematicComponent />)
      expect(queryByText('Error occurred')).toBeInTheDocument()
      rerender(
        <ErrorBoundary fallback={<div>Error occurred</div>} key="updated">
          <div>New child</div>
        </ErrorBoundary>,
      )
      expect(queryByText('New child')).toBeInTheDocument()
      expect(queryByText('Error occurred')).not.toBeInTheDocument()
      consoleErrorMock.mockRestore()
    })
  })

  describe('Boundary Scope', () => {
    it('does not catch errors outside of its child component tree', () => {
      expect(() =>
        render(
          <>
            <ErrorBoundary fallback={<div>Error occurred</div>}>
              <div>Child 1</div>
            </ErrorBoundary>
            <ProblematicComponent />
          </>,
        ),
      ).toThrow('Test error')
    })
  })
})

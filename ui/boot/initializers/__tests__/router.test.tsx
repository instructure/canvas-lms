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

import {act, render, screen} from '@testing-library/react'
import React from 'react'
import {FallbackSpinner, loadReactRouter} from '../router'

jest.mock('react-dom/client', () => ({
  createRoot: jest.fn(() => ({
    render: jest.fn(),
  })),
}))

describe('loadReactRouter', () => {
  let consoleErrorSpy: jest.SpyInstance

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
    document.body.innerHTML = '<div id="react-router-portals"></div>'
  })

  afterEach(() => {
    jest.clearAllMocks()
    document.body.innerHTML = ''
    consoleErrorSpy.mockRestore()
  })

  describe('FallbackSpinner', () => {
    it('renders correctly with loading text', () => {
      render(<FallbackSpinner />)
      const spinner = screen.getByTestId('fallback-spinner')
      expect(spinner).toBeInTheDocument()
      expect(screen.getByText('Loading page')).toBeInTheDocument()
    })
  })

  describe('loadReactRouter behavior', () => {
    it('does not crash if no mount node is found', () => {
      document.body.innerHTML = ''
      expect(() => loadReactRouter()).not.toThrow()
    })

    it('calls ReactDOM.createRoot and renders the router', () => {
      act(() => {
        loadReactRouter()
      })
      const {createRoot} = require('react-dom/client')
      const root = createRoot.mock.results[0].value
      expect(createRoot).toHaveBeenCalled()
      expect(root.render).toHaveBeenCalled()
    })

    it('renders RouterProvider with correct props', () => {
      act(() => {
        loadReactRouter()
      })
      const {createRoot} = require('react-dom/client')
      const root = createRoot.mock.results[0].value
      const renderedTree = root.render.mock.calls[0][0]
      expect(renderedTree).toBeTruthy()
    })

    it('does not render if no mountNode exists', () => {
      document.body.innerHTML = ''
      const {createRoot} = require('react-dom/client')
      act(() => {
        loadReactRouter()
      })
      expect(createRoot).not.toHaveBeenCalled()
    })
  })
})

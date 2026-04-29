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

import {render, screen} from '@testing-library/react'
import React from 'react'
import {FallbackSpinner, loadReactRouter} from '../router'

describe('loadReactRouter', () => {
  let consoleErrorSpy: any

  beforeEach(() => {
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    document.body.innerHTML = '<div id="react-router-portals"></div>'
  })

  afterEach(() => {
    vi.restoreAllMocks()
    document.body.innerHTML = ''
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

    it('does not crash when mount node exists', () => {
      expect(() => loadReactRouter()).not.toThrow()
    })
  })
})

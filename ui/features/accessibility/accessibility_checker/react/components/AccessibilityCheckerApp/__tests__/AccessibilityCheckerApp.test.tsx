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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'

import {AccessibilityCheckerApp} from '../AccessibilityCheckerApp'

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('AccessibilityCheckerApp', () => {
  beforeEach(() => {
    window.ENV.SCAN_DISABLED = false
  })

  it('renders without crashing - no scan limit exceeded Alert visible', () => {
    const Wrapper = createWrapper()
    render(<AccessibilityCheckerApp />, {wrapper: Wrapper})
    expect(screen.getByTestId('accessibility-checker-app')).toBeInTheDocument()

    const alert = screen.queryByTestId('accessibility-scan-disabled-alert')
    expect(alert).not.toBeInTheDocument()
  })

  it('renders scan limit exceeded Alert, when SCAN_DISABLED is true', () => {
    window.ENV.SCAN_DISABLED = true
    const Wrapper = createWrapper()
    render(<AccessibilityCheckerApp />, {wrapper: Wrapper})

    const alert = screen.getByTestId('accessibility-scan-disabled-alert')
    expect(alert).toBeInTheDocument()
  })
})

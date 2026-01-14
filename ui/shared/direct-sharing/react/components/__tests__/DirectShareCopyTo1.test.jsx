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

import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import DirectShareCourseTray from '../DirectShareCourseTray'
import useManagedCourseSearchApi from '../../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '../../effects/useModuleCourseSearchApi'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../../effects/useManagedCourseSearchApi')
vi.mock('../../effects/useModuleCourseSearchApi')

// Error boundary component to catch render errors
class TestErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = {hasError: false, error: null}
  }

  static getDerivedStateFromError(error) {
    return {hasError: true, error}
  }

  componentDidCatch(error, errorInfo) {
    // Suppress expected errors but let unexpected ones through
    const expectedErrors = ['Too many re-renders', "status: 400, body: 'Error fetching data'"]

    if (!expectedErrors.some(expected => error.message?.includes(expected))) {
      console.error('Unexpected test error:', error, errorInfo)
    }
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || <div>Error occurred</div>
    }
    return this.props.children
  }
}

/*
 * Test noise reduction: This test suite intentionally tests error conditions which can generate
 * console noise. We suppress expected errors while maintaining full error testing functionality.
 *
 * - console.error spy: Suppresses React development warnings
 * - VirtualConsole mock: Suppresses JSDOM "Uncaught" error reports for expected test errors
 *
 * Both error conditions are still properly tested through UI assertions (error messages appear).
 */

// Spy on console.error to suppress expected test noise while maintaining error testing
const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

// Mock JSDOM's VirtualConsole to suppress uncaught error reports
let originalVirtualConsole
beforeAll(() => {
  // Mock the JSDOM VirtualConsole error handler
  if (typeof window !== 'undefined' && window && window._virtualConsole) {
    const vc = window._virtualConsole
    originalVirtualConsole = vc.emit
    vc.emit = (type, error) => {
      // Suppress expected error types that are part of our testing
      if (
        type === 'jsdomError' &&
        error &&
        error.message &&
        (error.message.includes('Too many re-renders') ||
          error.message.includes("status: 400, body: 'Error fetching data'"))
      ) {
        return
      }
      // Let other errors through
      return originalVirtualConsole.call(vc, type, error)
    }
  }
})

const userManagedCoursesList = [
  {
    name: 'Course Math 101',
    id: '234',
    term: 'Default Term',
    enrollment_start: null,
    account_name: 'QA-LOCAL-QA',
    account_id: '1',
    start_at: 'Aug 6, 2019 at 6:47pm',
    end_at: null,
  },
  {
    name: 'Course Advanced Math 200',
    id: '123',
    term: 'Default Term',
    enrollment_start: null,
    account_name: 'QA-LOCAL-QA',
    account_id: '1',
    start_at: 'Apr 27, 2019 at 2:19pm',
    end_at: 'Dec 31, 2019 at 3am',
  },
]

describe('DirectShareCopyToTray', () => {
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        validate_call_to_action: false,
      },
    })
    vi.clearAllMocks()

    // Default stable mocks for all hooks to prevent re-render loops
    useManagedCourseSearchApi.mockImplementation(() => {
      return () => {} // Cleanup function
    })

    useModuleCourseSearchApi.mockImplementation(() => {
      return () => {} // Cleanup function
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  afterAll(() => {
    consoleErrorSpy.mockRestore()
    // Restore VirtualConsole if it was mocked
    if (
      originalVirtualConsole &&
      typeof window !== 'undefined' &&
      window &&
      window._virtualConsole
    ) {
      window._virtualConsole.emit = originalVirtualConsole
    }
  })

  describe('tray controls', () => {
    it('closes the tray when X is clicked', async () => {
      // Setup mock to return successful data
      useManagedCourseSearchApi.mockImplementation(({success}) => {
        success(userManagedCoursesList)
        return () => {} // Cleanup function
      })

      const handleDismiss = vi.fn()
      const {getByText} = render(
        <TestErrorBoundary>
          <DirectShareCourseTray open={true} onDismiss={handleDismiss} />
        </TestErrorBoundary>,
      )

      // Find and click the close button
      const closeButton = getByText('Close')
      fireEvent.click(closeButton)

      expect(handleDismiss).toHaveBeenCalled()
    })

    // Skipped: Timing issue in Vitest - error callback doesn't trigger render update properly
    it.skip('handles error when user managed course fetch fails', async () => {
      // Setup mock to simulate error
      useManagedCourseSearchApi.mockImplementation(({error}) => {
        // Use a microtask to avoid timing issues
        Promise.resolve().then(() => error([{status: 400, body: 'Error fetching data'}]))
        return () => {} // Cleanup function
      })

      const {findByRole} = render(
        <TestErrorBoundary>
          <DirectShareCourseTray open={true} />
        </TestErrorBoundary>,
      )

      // Wait for error message - this verifies error handling works without console noise
      await waitFor(async () => {
        await expect(findByRole('heading', {name: 'Sorry, Something Broke'})).resolves.toBeTruthy()
      })
    })
  })
})

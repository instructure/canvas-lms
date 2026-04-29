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

import React from 'react'
import {act, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {AccessibilityCourseScan} from '../AccessibilityCourseScan'
import {
  useAccessibilityScansStore,
  initialState,
} from '../../../../../shared/react/stores/AccessibilityScansStore'
import {ACCESSIBILITY_SCAN_QUERY_KEY, QUERY_LAST_SCAN} from '../constants'
const mockAlertScreenReader = vi.fn()
vi.mock('../../../../../shared/react/hooks/useScreenReaderAlert', () => ({
  useScreenReaderAlert: () => mockAlertScreenReader,
}))

const COURSE_ID = '1'
const COURSE_SCAN_URL = `/courses/${COURSE_ID}/accessibility/course_scan`

const server = setupServer()

const renderComponent = (queryClient?: QueryClient) => {
  const client =
    queryClient ?? new QueryClient({defaultOptions: {queries: {retry: false, gcTime: 0}}})
  return {
    ...render(
      <QueryClientProvider client={client}>
        <AccessibilityCourseScan courseId={COURSE_ID} scanDisabled={false}>
          <div />
        </AccessibilityCourseScan>
      </QueryClientProvider>,
    ),
    queryClient: client,
  }
}

describe('AccessibilityCourseScan focus management', () => {
  beforeAll(() => server.listen())

  beforeEach(() => {
    useAccessibilityScansStore.setState({isAutomaticScanEnabled: true})
  })

  afterEach(() => {
    server.resetHandlers()
    useAccessibilityScansStore.setState(initialState)
  })

  afterAll(() => server.close())

  it('moves focus to scanning view when scan is initiated', async () => {
    const user = userEvent.setup()

    server.use(
      http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'completed'})),
      http.post(COURSE_SCAN_URL, () => HttpResponse.json({id: 2, workflow_state: 'queued'})),
    )

    renderComponent()

    await waitFor(() => {
      expect(screen.getByRole('button', {name: 'Scan Course'})).toBeInTheDocument()
    })

    await user.click(screen.getByRole('button', {name: 'Scan Course'}))

    await waitFor(() => {
      expect(screen.getByText('Hang tight!')).toBeInTheDocument()
    })

    const srAnnouncement = screen.getByText(/Hang tight! Scanning might take/)
    expect(srAnnouncement).toHaveFocus()
  })

  it('moves focus to Update Report button and announces completion when scan completes', async () => {
    server.use(
      http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'queued'})),
    )

    const {queryClient} = renderComponent()

    // Component starts in scanning view
    await waitFor(() => {
      expect(screen.getByText('Hang tight!')).toBeInTheDocument()
    })

    // Simulate poll returning completed by updating the query cache directly
    act(() => {
      queryClient.setQueryData([ACCESSIBILITY_SCAN_QUERY_KEY, QUERY_LAST_SCAN, COURSE_ID], {
        id: 2,
        workflow_state: 'completed',
      })
    })

    // Scan completed: focus returns to the button
    await waitFor(() => {
      expect(screen.getByRole('button', {name: 'Scan Course'})).toHaveFocus()
    })

    expect(mockAlertScreenReader).toHaveBeenCalledWith('Report is ready')
  })
})

describe('AccessibilityCourseScan last checked date', () => {
  beforeAll(() => server.listen())

  afterEach(() => {
    server.resetHandlers()
    useAccessibilityScansStore.setState(initialState)
    delete (window.ENV as any).LOCALE
    delete (window.ENV as any).TIMEZONE
  })

  afterAll(() => server.close())

  beforeEach(() => {
    window.ENV.LOCALE = 'en-US'
    ;(window.ENV as any).TIMEZONE = 'UTC'
  })

  describe('when isAutomaticScanEnabled is false', () => {
    beforeEach(() => {
      useAccessibilityScansStore.setState({isAutomaticScanEnabled: false})
    })

    it('shows "Last checked" with the formatted date when scan is completed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () =>
          HttpResponse.json({
            id: 1,
            workflow_state: 'completed',
            created_at: '2026-04-03T13:30:00Z',
          }),
        ),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByText(/Last checked Apr 3, 2026/)).toBeInTheDocument()
      })
    })

    it('does not show "Last checked" when created_at is null', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () =>
          HttpResponse.json({id: 1, workflow_state: 'completed', created_at: null}),
        ),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.queryByText(/Last checked/)).not.toBeInTheDocument()
      })
    })

    it('does not show "Last checked" when scan is not completed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () =>
          HttpResponse.json({id: 1, workflow_state: 'failed', created_at: '2026-04-03T13:30:00Z'}),
        ),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.queryByText(/Last checked/)).not.toBeInTheDocument()
      })
    })
  })

  describe('when isAutomaticScanEnabled is true', () => {
    beforeEach(() => {
      useAccessibilityScansStore.setState({isAutomaticScanEnabled: true})
    })

    it('does not show "Last checked" even when scan is completed with a date', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () =>
          HttpResponse.json({
            id: 1,
            workflow_state: 'completed',
            created_at: '2026-04-03T13:30:00Z',
          }),
        ),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.queryByText(/Last checked/)).not.toBeInTheDocument()
      })
    })
  })
})

describe('AccessibilityCourseScan button labels', () => {
  beforeAll(() => server.listen())

  afterEach(() => {
    server.resetHandlers()
    useAccessibilityScansStore.setState(initialState)
  })

  afterAll(() => server.close())

  describe('when isAutomaticScanEnabled is true', () => {
    beforeEach(() => {
      useAccessibilityScansStore.setState({isAutomaticScanEnabled: true})
    })

    it('shows "Scan Course" when scan is completed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'completed'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Scan Course'})).toBeInTheDocument()
      })
    })

    it('shows "Scan Course" when last scan failed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'failed'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Scan Course'})).toBeInTheDocument()
      })
    })

    it('shows "Scan Course" when scan is queued', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'queued'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Scan Course'})).toBeInTheDocument()
      })
    })
  })

  describe('when isAutomaticScanEnabled is false', () => {
    beforeEach(() => {
      useAccessibilityScansStore.setState({isAutomaticScanEnabled: false})
    })

    it('shows "Update report" when scan is completed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'completed'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Update report'})).toBeInTheDocument()
      })
    })

    it('shows "Update report" when last scan failed', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'failed'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Update report'})).toBeInTheDocument()
      })
    })

    it('shows "Update report" when scan is queued', async () => {
      server.use(
        http.get(COURSE_SCAN_URL, () => HttpResponse.json({id: 1, workflow_state: 'queued'})),
      )

      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('button', {name: 'Update report'})).toBeInTheDocument()
      })
    })

    it('shows "Scan Course" when no scan exists regardless of feature flag', async () => {
      server.use(http.get(COURSE_SCAN_URL, () => HttpResponse.json(null, {status: 404})))

      renderComponent()

      // NoScanFoundView hardcodes scanCourseLabel, ignoring the feature flag.
      // Two "Scan Course" buttons: one in ScanHandler header, one as CondensedButton.
      await waitFor(() => {
        expect(screen.getAllByRole('button', {name: 'Scan Course'})).toHaveLength(2)
      })
    })
  })
})

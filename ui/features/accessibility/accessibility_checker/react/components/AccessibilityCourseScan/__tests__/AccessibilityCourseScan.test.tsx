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
import {render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {AccessibilityCourseScan} from '../AccessibilityCourseScan'
import {
  useAccessibilityScansStore,
  initialState,
} from '../../../../../shared/react/stores/AccessibilityScansStore'

const COURSE_ID = '1'
const COURSE_SCAN_URL = `/courses/${COURSE_ID}/accessibility/course_scan`

const server = setupServer()

const renderComponent = () => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false, gcTime: 0}},
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <AccessibilityCourseScan courseId={COURSE_ID} scanDisabled={false}>
        <div />
      </AccessibilityCourseScan>
    </QueryClientProvider>,
  )
}

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

/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ScanHandler} from '../components/ScanHandler'

describe('ScanHandler', () => {
  it('renders the heading', () => {
    render(
      <ScanHandler>
        <div />
      </ScanHandler>,
    )

    expect(screen.getByRole('heading', {name: 'Course Accessibility Checker'})).toBeInTheDocument()
  })

  it('renders children', () => {
    render(
      <ScanHandler>
        <div data-testid="child-content" />
      </ScanHandler>,
    )

    expect(screen.getByTestId('child-content')).toBeInTheDocument()
  })

  describe('button', () => {
    it('renders the button when buttonLabel is provided', () => {
      render(
        <ScanHandler buttonLabel="Scan Course">
          <div />
        </ScanHandler>,
      )

      expect(screen.getByRole('button', {name: 'Scan Course'})).toBeInTheDocument()
    })

    it('does not render a button when buttonLabel is omitted', () => {
      render(
        <ScanHandler>
          <div />
        </ScanHandler>,
      )

      expect(screen.queryByRole('button')).not.toBeInTheDocument()
    })

    it('calls handleCourseScan when clicked', async () => {
      const user = userEvent.setup()
      const handleCourseScan = vi.fn()

      render(
        <ScanHandler buttonLabel="Scan Course" handleCourseScan={handleCourseScan}>
          <div />
        </ScanHandler>,
      )

      await user.click(screen.getByRole('button', {name: 'Scan Course'}))

      expect(handleCourseScan).toHaveBeenCalledTimes(1)
    })

    it('disables the button when scanButtonDisabled is true', () => {
      render(
        <ScanHandler buttonLabel="Scan Course" scanButtonDisabled={true}>
          <div />
        </ScanHandler>,
      )

      expect(screen.getByRole('button', {name: 'Scan Course'})).toBeDisabled()
    })
  })

  describe('what we look for popover', () => {
    beforeEach(() => {
      window.ENV.LOCALE = 'en-US'
      ;(window.ENV as any).TIMEZONE = 'UTC'
    })

    afterEach(() => {
      delete (window.ENV as any).LOCALE
      delete (window.ENV as any).TIMEZONE
    })

    it('renders the popover trigger button when lastChecked is provided', () => {
      render(
        <ScanHandler lastChecked="2026-04-03T13:30:00Z">
          <div />
        </ScanHandler>,
      )

      expect(screen.getByRole('button', {name: 'What we look for'})).toBeInTheDocument()
    })

    it('does not render the popover trigger when lastChecked is omitted', () => {
      render(
        <ScanHandler>
          <div />
        </ScanHandler>,
      )

      expect(screen.queryByRole('button', {name: 'What we look for'})).not.toBeInTheDocument()
    })

    it('opens the popover when the trigger button is clicked', async () => {
      const user = userEvent.setup()

      render(
        <ScanHandler lastChecked="2026-04-03T13:30:00Z">
          <div />
        </ScanHandler>,
      )

      await user.click(screen.getByRole('button', {name: 'What we look for'}))

      expect(screen.getByRole('heading', {name: 'What we look for'})).toBeInTheDocument()
    })

    it('closes the popover when the close button is clicked', async () => {
      const user = userEvent.setup()

      render(
        <ScanHandler lastChecked="2026-04-03T13:30:00Z">
          <div />
        </ScanHandler>,
      )

      await user.click(screen.getByRole('button', {name: 'What we look for'}))
      await user.click(screen.getByRole('button', {name: 'Close'}))

      expect(screen.queryByRole('heading', {name: 'What we look for'})).not.toBeInTheDocument()
    })
  })

  describe('last checked date', () => {
    beforeEach(() => {
      window.ENV.LOCALE = 'en-US'
      ;(window.ENV as any).TIMEZONE = 'UTC'
    })

    afterEach(() => {
      delete (window.ENV as any).LOCALE
      delete (window.ENV as any).TIMEZONE
    })

    it('renders "Last checked" text with formatted date when lastChecked is provided', () => {
      render(
        <ScanHandler lastChecked="2026-04-03T13:30:00Z">
          <div />
        </ScanHandler>,
      )

      expect(screen.getByText(/Last checked Apr 3, 2026, 1:30 PM/)).toBeInTheDocument()
    })

    it('does not render "Last checked" text when lastChecked is omitted', () => {
      render(
        <ScanHandler>
          <div />
        </ScanHandler>,
      )

      expect(screen.queryByText(/Last checked/)).not.toBeInTheDocument()
    })

    it('does not render "Last checked" text when lastChecked is null', () => {
      render(
        <ScanHandler lastChecked={null}>
          <div />
        </ScanHandler>,
      )

      expect(screen.queryByText(/Last checked/)).not.toBeInTheDocument()
    })
  })
})

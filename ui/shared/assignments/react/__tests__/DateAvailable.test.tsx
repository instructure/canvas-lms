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
import DateAvailable from '../DateAvailable'
import type {DateAvailableProps} from '../DateAvailable'

const pastDate = '2020-01-01T00:00:00Z'
const futureDate = '2024-12-30T23:59:59Z'
const farFutureDate = '2099-12-31T23:59:59Z'

function renderComponent(overrides: Partial<DateAvailableProps> = {}) {
  const defaults: DateAvailableProps = {
    multipleDueDates: false,
    allDates: [],
    defaultDates: {pending: false, open: false, closed: false, unlockAt: null, lockAt: null},
    linkHref: '/courses/1/assignments/1',
    ...overrides,
  }
  return render(<DateAvailable {...defaults} />)
}

describe('DateAvailable', () => {
  describe('single date (not multiple due dates)', () => {
    it('renders "Not available until" when pending', () => {
      renderComponent({
        defaultDates: {
          pending: true,
          open: false,
          closed: false,
          unlockAt: futureDate,
          lockAt: null,
        },
      })

      expect(screen.getByText('Not available until')).toBeInTheDocument()
    })

    it('renders "Available until" when open', () => {
      renderComponent({
        defaultDates: {
          pending: false,
          open: true,
          closed: false,
          unlockAt: null,
          lockAt: futureDate,
        },
      })

      expect(screen.getByText('Available until')).toBeInTheDocument()
    })

    it('renders "Closed" when closed', () => {
      renderComponent({
        defaultDates: {pending: false, open: false, closed: true, unlockAt: null, lockAt: pastDate},
      })

      expect(screen.getByText('Closed')).toBeInTheDocument()
    })

    it('renders "Available" when available', () => {
      renderComponent({
        defaultDates: {
          pending: false,
          open: false,
          closed: false,
          available: true,
          unlockAt: null,
          lockAt: null,
        },
      })

      expect(screen.getByText('Available')).toBeInTheDocument()
    })

    it('renders nothing when no status flags are set', () => {
      const {container} = renderComponent({
        defaultDates: {pending: false, open: false, closed: false, unlockAt: null, lockAt: null},
      })

      expect(container.querySelector('.default-dates')).toBeInTheDocument()
    })
  })

  describe('multiple due dates', () => {
    it('renders "Available" label and "Multiple Dates" link', () => {
      renderComponent({
        multipleDueDates: true,
        allDates: [
          {
            dueFor: 'Section A',
            unlockAt: pastDate,
            lockAt: futureDate,
            pending: false,
            open: true,
            closed: false,
          },
          {
            dueFor: 'Section B',
            unlockAt: futureDate,
            lockAt: farFutureDate,
            pending: true,
            open: false,
            closed: false,
          },
        ],
        linkHref: '/courses/1/assignments/1',
      })

      expect(screen.getByText('Available')).toBeInTheDocument()
      expect(screen.getByText('Multiple Dates')).toBeInTheDocument()
    })

    it('renders "Multiple Dates" as a link when linkHref is provided', () => {
      renderComponent({
        multipleDueDates: true,
        allDates: [
          {
            dueFor: 'Section A',
            unlockAt: pastDate,
            lockAt: futureDate,
            pending: false,
            open: true,
            closed: false,
          },
        ],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByText('Multiple Dates')
      expect(link).toHaveAttribute('href', '/courses/1/assignments/1')
    })

    it('shows tooltip with section details on hover', async () => {
      const user = userEvent.setup()

      renderComponent({
        multipleDueDates: true,
        allDates: [
          {
            dueFor: 'Section A',
            unlockAt: pastDate,
            lockAt: futureDate,
            pending: false,
            open: true,
            closed: false,
          },
          {
            dueFor: 'Section B',
            unlockAt: futureDate,
            lockAt: null,
            pending: true,
            open: false,
            closed: false,
          },
        ],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByText('Multiple Dates')
      await user.hover(link)

      expect(await screen.findByText('Section A')).toBeInTheDocument()
      expect(await screen.findByText('Section B')).toBeInTheDocument()
    })

    it('shows "Available" status in tooltip for available sections', async () => {
      const user = userEvent.setup()

      renderComponent({
        multipleDueDates: true,
        allDates: [
          {
            dueFor: 'Play Course',
            available: true,
            pending: false,
            open: false,
            closed: false,
            unlockAt: null,
            lockAt: null,
          },
          {
            dueFor: 'Section B',
            available: true,
            pending: false,
            open: false,
            closed: false,
            unlockAt: null,
            lockAt: null,
          },
        ],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByText('Multiple Dates')
      await user.hover(link)

      expect(await screen.findByText('Play Course')).toBeInTheDocument()
      expect(await screen.findByText('Section B')).toBeInTheDocument()
      const availableTexts = await screen.findAllByText('Available')
      expect(availableTexts.length).toBeGreaterThanOrEqual(3)
    })

    it('renders "Multiple Dates" text without link when no allDates', () => {
      renderComponent({
        multipleDueDates: true,
        allDates: [],
      })

      expect(screen.getByText('Multiple Dates')).toBeInTheDocument()
      expect(screen.queryByRole('link', {name: 'Multiple Dates'})).not.toBeInTheDocument()
    })
  })
})

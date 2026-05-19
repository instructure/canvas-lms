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
import DateDue from '../DateDue'
import type {DateDueProps} from '../DateDue'

const futureDate = '2099-12-31T23:59:59Z'
const anotherFutureDate = '2099-06-15T12:00:00Z'

function renderComponent(overrides: Partial<DateDueProps> = {}) {
  const defaults: DateDueProps = {
    multipleDueDates: false,
    allDates: [],
    singleSectionDueDate: null,
    todoDate: null,
    linkHref: '/courses/1/assignments/1',
    ...overrides,
  }
  return render(<DateDue {...defaults} />)
}

describe('DateDue', () => {
  describe('single due date', () => {
    it('renders "Due" label with date when singleSectionDueDate is set', () => {
      renderComponent({singleSectionDueDate: futureDate})

      expect(screen.getByText('Due')).toBeInTheDocument()
    })

    it('renders "To do" label with date when todoDate is set', () => {
      renderComponent({todoDate: futureDate})

      expect(screen.getByText('To do')).toBeInTheDocument()
    })

    it('renders nothing when no due date or todo date', () => {
      const {container} = renderComponent()

      expect(container.textContent).toBe('')
    })
  })

  describe('multiple due dates', () => {
    it('renders "Due" label and "Multiple Dates" link', () => {
      renderComponent({
        multipleDueDates: true,
        allDates: [
          {dueFor: 'Section A', dueAt: futureDate},
          {dueFor: 'Section B', dueAt: anotherFutureDate},
        ],
      })

      expect(screen.getByText('Due')).toBeInTheDocument()
      expect(screen.getByText('Multiple Dates')).toBeInTheDocument()
    })

    it('renders "Multiple Dates" as a link when linkHref is provided', () => {
      renderComponent({
        multipleDueDates: true,
        allDates: [{dueFor: 'Section A', dueAt: futureDate}],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByRole('link', {name: 'Multiple Dates'})
      expect(link).toHaveAttribute('href', '/courses/1/assignments/1')
    })

    it('shows tooltip with section due dates on hover', async () => {
      const user = userEvent.setup()

      renderComponent({
        multipleDueDates: true,
        allDates: [
          {dueFor: 'Section A', dueAt: futureDate},
          {dueFor: 'Section B', dueAt: null},
        ],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByRole('link', {name: 'Multiple Dates'})
      await user.hover(link)

      expect(await screen.findByText('Section A')).toBeInTheDocument()
      expect(await screen.findByText('Section B')).toBeInTheDocument()
    })

    it('shows "-" for sections without a due date in tooltip', async () => {
      const user = userEvent.setup()

      renderComponent({
        multipleDueDates: true,
        allDates: [{dueFor: 'Section A', dueAt: null}],
        linkHref: '/courses/1/assignments/1',
      })

      const link = screen.getByRole('link', {name: 'Multiple Dates'})
      await user.hover(link)

      expect(await screen.findByText('-')).toBeInTheDocument()
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

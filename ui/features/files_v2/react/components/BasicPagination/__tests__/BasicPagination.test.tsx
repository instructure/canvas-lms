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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {BasicPagination, BasicPaginationProps} from '../BasicPagination'

describe('BasicPagination', () => {
  const defaultProps: BasicPaginationProps = {
    labelNext: 'Next page',
    labelPrev: 'Previous page',
    currentPage: 1,
    perPage: 10,
    totalItems: 100,
    onNext: vi.fn(),
    onPrev: vi.fn(),
  }

  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('when on first page', () => {
    it('should disable the previous button', () => {
      render(<BasicPagination {...defaultProps} currentPage={1} />)

      const prevButton = screen.getByRole('button', {name: /previous page/i})
      expect(prevButton).toBeDisabled()
    })

    it('should enable the next button when there are multiple pages', () => {
      render(<BasicPagination {...defaultProps} currentPage={1} totalItems={100} />)

      const nextButton = screen.getByRole('button', {name: /next page/i})
      expect(nextButton).toBeEnabled()
    })
  })

  describe('when on last page', () => {
    it('should disable the next button', () => {
      render(<BasicPagination {...defaultProps} currentPage={10} totalItems={100} />)

      const nextButton = screen.getByRole('button', {name: /next page/i})
      expect(nextButton).toBeDisabled()
    })

    it('should enable the previous button when on last page', () => {
      render(<BasicPagination {...defaultProps} currentPage={10} totalItems={100} />)

      const prevButton = screen.getByRole('button', {name: /previous page/i})
      expect(prevButton).toBeEnabled()
    })
  })

  describe('when on middle page', () => {
    it('should enable both buttons when on a middle page', () => {
      render(<BasicPagination {...defaultProps} currentPage={5} totalItems={100} />)

      const prevButton = screen.getByRole('button', {name: /previous page/i})
      const nextButton = screen.getByRole('button', {name: /next page/i})

      expect(prevButton).toBeEnabled()
      expect(nextButton).toBeEnabled()
    })
  })

  describe('when there is only one page', () => {
    it('should disable both buttons', () => {
      render(<BasicPagination {...defaultProps} currentPage={1} totalItems={5} />)

      const prevButton = screen.getByRole('button', {name: /previous page/i})
      const nextButton = screen.getByRole('button', {name: /next page/i})

      expect(prevButton).toBeDisabled()
      expect(nextButton).toBeDisabled()
    })
  })

  describe('callback functions', () => {
    it('should call onNext when next button is clicked', async () => {
      const user = userEvent.setup()
      const onNext = vi.fn()

      render(<BasicPagination {...defaultProps} currentPage={1} onNext={onNext} />)

      const nextButton = screen.getByRole('button', {name: /next page/i})
      await user.click(nextButton)

      expect(onNext).toHaveBeenCalledTimes(1)
    })

    it('should call onPrev when previous button is clicked', async () => {
      const user = userEvent.setup()
      const onPrev = vi.fn()

      render(<BasicPagination {...defaultProps} currentPage={2} onPrev={onPrev} />)

      const prevButton = screen.getByRole('button', {name: /previous page/i})
      await user.click(prevButton)

      expect(onPrev).toHaveBeenCalledTimes(1)
    })
  })

  describe('page information display', () => {
    it('should display correct page information', () => {
      render(<BasicPagination {...defaultProps} currentPage={3} totalItems={100} perPage={10} />)
      expect(screen.getByText(/21-30 of 100/)).toBeInTheDocument()
    })

    it('should display correct page information for last page with fewer items', () => {
      render(<BasicPagination {...defaultProps} currentPage={10} totalItems={95} perPage={10} />)
      expect(screen.getByText(/91-95 of 95/)).toBeInTheDocument()
    })

    it('should display correct page information for first page', () => {
      render(
        <BasicPagination {...defaultProps} currentPage={101} totalItems={10000} perPage={10} />,
      )
      expect(screen.getByText(/1,001-1,010 of 10,000/)).toBeInTheDocument()
    })
  })
})

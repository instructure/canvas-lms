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
import AllocationConverterMessage from '../AllocationConverterMessage'
import type {ConversionAction, ConversionJobState} from '../../graphql/hooks/useConvertAllocations'

describe('AllocationConverterMessage', () => {
  const launchConversion = vi.fn()
  const launchDeletion = vi.fn()
  let user: ReturnType<typeof userEvent.setup>

  const defaultProps = {
    hasLegacyAllocations: true,
    conversionJobState: 'not_started' as ConversionJobState,
    conversionJobError: null as string | null,
    conversionAction: 'convert' as ConversionAction,
    isConversionInProgress: false,
    launchConversion,
    launchDeletion,
  }

  beforeEach(() => {
    vi.clearAllMocks()
    user = userEvent.setup()
  })

  it('returns nothing when hasLegacyAllocations is false', () => {
    const {container} = render(
      <AllocationConverterMessage {...defaultProps} hasLegacyAllocations={false} />,
    )
    expect(container.firstChild).toBeNull()
  })

  it('returns nothing when conversionJobState is complete', () => {
    const {container} = render(
      <AllocationConverterMessage {...defaultProps} conversionJobState="complete" />,
    )
    expect(container.firstChild).toBeNull()
  })

  describe('default state (not_started)', () => {
    it('shows warning alert with instruction text', () => {
      render(<AllocationConverterMessage {...defaultProps} />)

      expect(screen.getByTestId('legacy-allocations-alert')).toBeInTheDocument()
      expect(
        screen.getByText(/has peer review allocations that are in the old format/),
      ).toBeInTheDocument()
    })

    it('shows Delete and Convert buttons', () => {
      render(<AllocationConverterMessage {...defaultProps} />)

      expect(screen.getByTestId('legacy-allocations-delete-button')).toBeInTheDocument()
      expect(screen.getByTestId('legacy-allocations-convert-button')).toBeInTheDocument()
    })

    it('calls launchConversion when Convert is clicked', async () => {
      render(<AllocationConverterMessage {...defaultProps} />)

      await user.click(screen.getByTestId('legacy-allocations-convert-button'))
      expect(launchConversion).toHaveBeenCalledTimes(1)
    })

    it('calls launchDeletion when Delete is clicked', async () => {
      render(<AllocationConverterMessage {...defaultProps} />)

      await user.click(screen.getByTestId('legacy-allocations-delete-button'))
      expect(launchDeletion).toHaveBeenCalledTimes(1)
    })
  })

  describe('in-progress state', () => {
    it('shows info alert with conversion progress text and spinner', () => {
      render(
        <AllocationConverterMessage
          {...defaultProps}
          isConversionInProgress={true}
          conversionJobState="queued"
          conversionAction="convert"
        />,
      )

      expect(screen.getByTestId('legacy-allocations-converting-alert')).toBeInTheDocument()
      expect(screen.getByText('Allocation conversion in progress')).toBeInTheDocument()
      expect(screen.getByTestId('legacy-allocations-converting-spinner')).toBeInTheDocument()
    })

    it('shows info alert with deletion progress text and spinner', () => {
      render(
        <AllocationConverterMessage
          {...defaultProps}
          isConversionInProgress={true}
          conversionJobState="running"
          conversionAction="delete"
        />,
      )

      expect(screen.getByTestId('legacy-allocations-converting-alert')).toBeInTheDocument()
      expect(screen.getByText('Allocation deletion in progress')).toBeInTheDocument()
      expect(screen.getByTestId('legacy-allocations-converting-spinner')).toBeInTheDocument()
    })
  })

  describe('failed state', () => {
    it('shows error alert with conversion error message', () => {
      render(
        <AllocationConverterMessage
          {...defaultProps}
          conversionJobState="failed"
          conversionAction="convert"
        />,
      )

      expect(screen.getByTestId('legacy-allocations-error-alert')).toBeInTheDocument()
      expect(
        screen.getByText('An error occurred while converting allocations.'),
      ).toBeInTheDocument()
    })

    it('shows error alert with deletion error message', () => {
      render(
        <AllocationConverterMessage
          {...defaultProps}
          conversionJobState="failed"
          conversionAction="delete"
        />,
      )

      expect(screen.getByTestId('legacy-allocations-error-alert')).toBeInTheDocument()
      expect(screen.getByText('An error occurred while deleting allocations.')).toBeInTheDocument()
    })

    it('shows custom conversionJobError when provided', () => {
      render(
        <AllocationConverterMessage
          {...defaultProps}
          conversionJobState="failed"
          conversionJobError="Custom error from server"
        />,
      )

      expect(screen.getByTestId('legacy-allocations-error-alert')).toBeInTheDocument()
      expect(screen.getByText('Custom error from server')).toBeInTheDocument()
    })
  })
})

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
import {cleanup, render, screen} from '@testing-library/react'
import MessageAlert from '../MessageAlert'
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest'

vi.mock('@canvas/i18n', () => ({
  useScope: () => ({
    t: (s: string) => s,
  }),
}))

vi.mock('@instructure/ui-alerts', () => ({
  Alert: ({
    children,
    'data-testid': dataTestId,
    variant,
    variantScreenReaderLabel,
    hasShadow,
  }: {
    children: React.ReactNode
    'data-testid'?: string
    variant?: string
    variantScreenReaderLabel?: string
    hasShadow?: boolean
  }) => (
    <div
      data-testid={dataTestId}
      data-variant={variant}
      data-variant-sr-label={variantScreenReaderLabel}
      data-has-shadow={String(hasShadow)}
    >
      {children}
    </div>
  ),
}))

vi.mock('@instructure/ui-text', () => ({
  Text: ({children, wrap}: {children: React.ReactNode; wrap?: string}) => (
    <span data-wrap={wrap}>{children}</span>
  ),
}))

describe('MessageAlert', () => {
  afterEach(() => {
    cleanup()
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the message', () => {
    render(<MessageAlert message="Hello world" />)
    expect(screen.getByText('Hello world')).toBeInTheDocument()
  })

  it('defaults variant to info', () => {
    render(<MessageAlert message="Hello world" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-variant', 'info')
  })

  it('sets hasShadow to false', () => {
    render(<MessageAlert message="Hello world" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-has-shadow', 'false')
  })

  it('sets the screen reader label for info by default', () => {
    render(<MessageAlert message="Hello world" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-variant-sr-label', 'Information,')
  })

  it('sets the screen reader label for success', () => {
    render(<MessageAlert message="Hello world" variant="success" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-variant', 'success')
    expect(alert).toHaveAttribute('data-variant-sr-label', 'Success,')
  })

  it('sets the screen reader label for warning', () => {
    render(<MessageAlert message="Hello world" variant="warning" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-variant', 'warning')
    expect(alert).toHaveAttribute('data-variant-sr-label', 'Warning,')
  })

  it('sets the screen reader label for error', () => {
    render(<MessageAlert message="Hello world" variant="error" />)
    const alert = screen.getByTestId('custom-message-alert')
    expect(alert).toHaveAttribute('data-variant', 'error')
    expect(alert).toHaveAttribute('data-variant-sr-label', 'Error,')
  })
})

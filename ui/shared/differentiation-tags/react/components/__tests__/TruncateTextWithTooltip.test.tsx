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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom'
import TruncateTextWithTooltip from '../TruncateTextWithTooltip'

jest.mock('@instructure/ui-truncate-text', () => ({
  TruncateText: ({
    children,
    onUpdate,
  }: {
    children: React.ReactNode
    onUpdate: (truncated: boolean) => void
  }) => {
    return (
      <div
        data-testid="truncate-text"
        role="button"
        tabIndex={0}
        onClick={() => onUpdate(true)}
        onKeyDown={event => {
          if (event.key === 'Enter' || event.key === ' ') {
            onUpdate(true)
          }
        }}
      >
        {children}
      </div>
    )
  },
}))

jest.mock('@instructure/ui-tooltip', () => ({
  Tooltip: ({
    children,
    renderTip,
    ...props
  }: {
    children: React.ReactNode
    renderTip: () => React.ReactNode
  }) => {
    return (
      <div data-testid="tooltip-container" {...props}>
        {children}
        <div data-testid="tooltip-content">{renderTip()}</div>
      </div>
    )
  },
}))

describe('TruncateTextWithTooltip', () => {
  test('renders children without tooltip initially', () => {
    render(<TruncateTextWithTooltip>Test Content</TruncateTextWithTooltip>)
    expect(screen.getByText('Test Content')).toBeInTheDocument()
    expect(screen.queryByTestId('tooltip-container')).not.toBeInTheDocument()
  })

  test('renders tooltip when text is truncated', async () => {
    render(<TruncateTextWithTooltip>Truncated Content</TruncateTextWithTooltip>)
    const user = userEvent.setup()
    await user.click(screen.getByTestId('truncate-text'))
    expect(screen.getByTestId('tooltip-container')).toBeInTheDocument()
    expect(screen.getByTestId('tooltip-content')).toHaveTextContent('Truncated Content')
  })

  test('resets truncation state when children prop changes', async () => {
    const {rerender} = render(<TruncateTextWithTooltip>Initial Content</TruncateTextWithTooltip>)
    const user = userEvent.setup()
    await user.click(screen.getByTestId('truncate-text'))
    expect(screen.getByTestId('tooltip-container')).toBeInTheDocument()

    rerender(<TruncateTextWithTooltip>Updated Content</TruncateTextWithTooltip>)
    expect(screen.queryByTestId('tooltip-container')).not.toBeInTheDocument()
    expect(screen.getByText('Updated Content')).toBeInTheDocument()
  })
})

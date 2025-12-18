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
import {render, screen, fireEvent} from '@testing-library/react'
import NotificationAlert, {AccountNotificationData} from '../NotificationAlert'

describe('NotificationAlert', () => {
  const mockOnDismiss = vi.fn()

  const baseNotification: AccountNotificationData = {
    id: '1',
    subject: 'Test Subject',
    message: '<p>Test message content</p>',
    startAt: '2025-01-01T00:00:00Z',
    endAt: '2025-12-31T23:59:59Z',
    accountName: 'Test Account',
    siteAdmin: false,
    notificationType: 'info',
  }

  beforeEach(() => {
    mockOnDismiss.mockClear()
  })

  it('renders notification with subject and message', () => {
    render(<NotificationAlert notification={baseNotification} onDismiss={mockOnDismiss} />)

    expect(screen.getByText('Test Subject')).toBeInTheDocument()
    expect(screen.getByText('Test message content')).toBeInTheDocument()
  })

  it('displays site admin message when notification is from site admin', () => {
    const siteAdminNotification = {
      ...baseNotification,
      siteAdmin: true,
    }

    render(<NotificationAlert notification={siteAdminNotification} onDismiss={mockOnDismiss} />)

    expect(screen.getByText('This is a message from')).toBeInTheDocument()
    expect(screen.getByText('Canvas Administration')).toBeInTheDocument()
  })

  it('displays account name when notification is not from site admin', () => {
    render(<NotificationAlert notification={baseNotification} onDismiss={mockOnDismiss} />)

    expect(screen.getByText('This is a message from')).toBeInTheDocument()
    expect(screen.getByText('Test Account')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    render(<NotificationAlert notification={baseNotification} onDismiss={mockOnDismiss} />)

    const closeButton = screen.getByText('Close')
    fireEvent.click(closeButton)

    expect(mockOnDismiss).toHaveBeenCalledWith('1')
  })

  it('renders warning variant for warning notifications', () => {
    const warningNotification = {
      ...baseNotification,
      notificationType: 'warning',
    }

    const {container} = render(
      <NotificationAlert notification={warningNotification} onDismiss={mockOnDismiss} />,
    )

    const alertContainer = container.querySelector('[class*="view-alert"]')
    expect(alertContainer).toBeInTheDocument()

    const iconSvg = container.querySelector('svg')
    expect(iconSvg).toBeInTheDocument()
  })

  it('renders error variant for error notifications', () => {
    const errorNotification = {
      ...baseNotification,
      notificationType: 'error',
    }

    const {container} = render(
      <NotificationAlert notification={errorNotification} onDismiss={mockOnDismiss} />,
    )

    const alertContainer = container.querySelector('[class*="view-alert"]')
    expect(alertContainer).toBeInTheDocument()

    const iconSvg = container.querySelector('svg')
    expect(iconSvg).toBeInTheDocument()
  })

  it('renders HTML content safely', () => {
    const htmlNotification = {
      ...baseNotification,
      message: '<strong>Bold text</strong> and <a href="#">link</a>',
    }

    render(<NotificationAlert notification={htmlNotification} onDismiss={mockOnDismiss} />)

    const strongElement = screen.getByText('Bold text')
    expect(strongElement.tagName).toBe('STRONG')

    const linkElement = screen.getByText('link')
    expect(linkElement.tagName).toBe('A')
  })

  it('sanitizes HTML content using sanitize-html-with-tinymce', () => {
    const htmlNotification = {
      ...baseNotification,
      message: '<script>alert("xss")</script><p>Safe content</p><strong>Bold</strong>',
    }

    render(<NotificationAlert notification={htmlNotification} onDismiss={mockOnDismiss} />)

    expect(screen.getByText('Safe content')).toBeInTheDocument()
    expect(screen.getByText('Bold')).toBeInTheDocument()
    expect(screen.queryByText('alert("xss")')).not.toBeInTheDocument()
  })
})

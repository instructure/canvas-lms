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

import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import WhyMattersPopover from '../WhyMattersPopover'
import {FormType, IssueWorkflowState, type AccessibilityIssue} from '../../../types'

describe('WhyMattersPopover', () => {
  const mockIssue: AccessibilityIssue = {
    id: 'test-issue-1',
    ruleId: 'test-rule',
    displayName: 'Test Issue',
    message: 'Test message',
    why: 'This is why it matters',
    element: '<div>test element</div>',
    path: '/test/path',
    workflowState: IssueWorkflowState.Active,
    form: {
      type: FormType.Button,
      label: 'Fix it',
      canGenerateFix: true,
    },
    issueUrl: 'https://example.com/wcag',
  }

  it('renders the trigger button', () => {
    render(<WhyMattersPopover issue={mockIssue} />)
    const button = screen.getByTestId('why-it-matters-button')
    expect(button).toBeInTheDocument()
  })

  it('shows popover content when button is clicked', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByRole('dialog')).toHaveAttribute('aria-label', 'Why it matters')
  })

  it('displays the heading and content', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    expect(screen.getByRole('heading', {name: 'Why it matters'})).toBeInTheDocument()
    expect(screen.getByText('This is why it matters')).toBeInTheDocument()
  })

  it('displays multiple paragraphs when why is an array', async () => {
    const user = userEvent.setup()
    const issueWithMultipleWhy: AccessibilityIssue = {
      ...mockIssue,
      why: ['First reason', 'Second reason', 'Third reason'],
    }
    render(<WhyMattersPopover issue={issueWithMultipleWhy} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    expect(screen.getByText('First reason')).toBeInTheDocument()
    expect(screen.getByText('Second reason')).toBeInTheDocument()
    expect(screen.getByText('Third reason')).toBeInTheDocument()
  })

  it('displays WCAG requirement link when issueUrl is provided', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    const link = screen.getByRole('link', {name: /WCAG requirement/i})
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', 'https://example.com/wcag')
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('does not display WCAG section when issueUrl is not provided', async () => {
    const user = userEvent.setup()
    const issueWithoutUrl: AccessibilityIssue = {
      ...mockIssue,
      issueUrl: undefined,
    }
    render(<WhyMattersPopover issue={issueWithoutUrl} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    expect(screen.queryByText(/IMPORTANT/i)).not.toBeInTheDocument()
    expect(screen.queryByRole('link', {name: /WCAG requirement/i})).not.toBeInTheDocument()
  })

  it('closes popover when close button is clicked', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    expect(screen.getByRole('dialog')).toBeInTheDocument()

    const closeButton = screen.getByRole('button', {name: /close/i})
    await user.click(closeButton)

    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('ensures dialog has proper ARIA attributes for accessibility', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    const dialog = screen.getByRole('dialog')
    expect(dialog).toHaveAttribute('role', 'dialog')
    expect(dialog).toHaveAttribute('aria-label', 'Why it matters')
  })

  it('renders IMPORTANT as a heading for screen reader navigation', async () => {
    const user = userEvent.setup()
    render(<WhyMattersPopover issue={mockIssue} />)

    const button = screen.getByTestId('why-it-matters-button')
    await user.click(button)

    const importantHeading = screen.getByText('IMPORTANT').closest('h4')
    expect(importantHeading).toBeInTheDocument()
  })
})

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
import {CloseRemediationModal} from '../CloseRemediationModal'
import {
  AccessibilityResourceScan,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
} from '../../../../../../shared/react/types'

describe('CloseRemediationModal', () => {
  const mockScan: AccessibilityResourceScan = {
    id: 1,
    courseId: 100,
    resourceId: 10,
    resourceType: ResourceType.WikiPage,
    resourceName: 'Test Page',
    resourceWorkflowState: ResourceWorkflowState.Published,
    resourceUpdatedAt: '2025-01-01T00:00:00Z',
    resourceUrl: '/courses/100/pages/test-page',
    workflowState: ScanWorkflowState.Completed,
    issueCount: 5,
    closedAt: null,
  }

  const mockOnClose = jest.fn()
  const mockOnReopen = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
    localStorage.clear()
  })

  it('renders modal when isOpen is true', () => {
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByText(/you closed remediation/i)).toBeInTheDocument()
  })

  it('does not render modal when isOpen is false', () => {
    render(
      <CloseRemediationModal
        isOpen={false}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.queryByText(/you closed remediation/i)).not.toBeInTheDocument()
  })

  it('displays the resource name and issue count', () => {
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByText(/test page/i)).toBeInTheDocument()
    expect(screen.getByText(/5 issues/i)).toBeInTheDocument()
  })

  it('displays the remediation closed message', () => {
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByText(/you have closed accessibility remediation/i)).toBeInTheDocument()
    expect(
      screen.getByText(/will no longer count towards unresolved issues statistics/i),
    ).toBeInTheDocument()
  })

  it('displays the reopening information', () => {
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByText(/if you edit this resource, it will be reopened/i)).toBeInTheDocument()
  })

  it('displays "Don\'t show this again" checkbox', () => {
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByLabelText(/don't show this again/i)).toBeInTheDocument()
  })

  it('toggles "Don\'t show this again" checkbox when clicked', async () => {
    const user = userEvent.setup()
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    const checkbox = screen.getByLabelText(/don't show this again/i)
    expect(checkbox).not.toBeChecked()

    await user.click(checkbox)
    expect(checkbox).toBeChecked()

    await user.click(checkbox)
    expect(checkbox).not.toBeChecked()
  })

  it('calls onReopen when Reopen button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    const reopenButton = screen.getByText(/^reopen$/i)
    await user.click(reopenButton.closest('button')!)

    expect(mockOnReopen).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when OK button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    const okButton = screen.getByText(/^ok$/i)
    await user.click(okButton.closest('button')!)

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('displays singular issue count when there is 1 issue', () => {
    const scanWithOneIssue = {...mockScan, issueCount: 1}
    render(
      <CloseRemediationModal
        isOpen={true}
        scan={scanWithOneIssue}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    expect(screen.getByText(/1 issue/i)).toBeInTheDocument()
  })

  it('persists checkbox state in localStorage when checked and modal is reopened', async () => {
    const user = userEvent.setup()
    const {rerender} = render(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    const checkbox = screen.getByLabelText(/don't show this again/i)
    await user.click(checkbox)
    expect(checkbox).toBeChecked()

    // Click OK to save to localStorage
    const okButton = screen.getByText(/^ok$/i)
    await user.click(okButton.closest('button')!)

    expect(mockOnClose).toHaveBeenCalled()
    expect(localStorage.getItem('accessibility_checker_dont_show_close_remediation_modal')).toBe(
      'true',
    )

    // Close modal
    rerender(
      <CloseRemediationModal
        isOpen={false}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    // Reopen modal
    rerender(
      <CloseRemediationModal
        isOpen={true}
        scan={mockScan}
        onClose={mockOnClose}
        onReopen={mockOnReopen}
      />,
    )

    const newCheckbox = screen.getByLabelText(/don't show this again/i)
    expect(newCheckbox).toBeChecked()
  })
})

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
import {MissingPolicyWarningModal} from '../MissingPolicyWarningModal'

describe('MissingPolicyWarningModal', () => {
  const defaultProps = {
    open: true,
    onCancel: jest.fn(),
    onDisablePolicy: jest.fn(),
    onImportAnyway: jest.fn(),
    isDisabling: false,
    scenario: 'destination' as const,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the modal when open is true', () => {
    render(<MissingPolicyWarningModal {...defaultProps} />)
    expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
    expect(
      screen.getByText('Warning: This course has Automatic Missing Policy enabled'),
    ).toBeInTheDocument()
  })

  it('does not render the modal when open is false', () => {
    render(<MissingPolicyWarningModal {...defaultProps} open={false} />)
    expect(screen.queryByTestId('missing-policy-warning-modal')).not.toBeInTheDocument()
  })

  it('renders with no heading or body text when scenario is null', () => {
    render(<MissingPolicyWarningModal {...defaultProps} scenario={null} />)
    expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
    expect(screen.queryByText(/Warning:/)).not.toBeInTheDocument()
    expect(screen.queryByText(/If any imported assignments/)).not.toBeInTheDocument()
    expect(screen.queryByText(/To avoid this/)).not.toBeInTheDocument()
  })

  it('displays the warning message about past due dates', () => {
    render(<MissingPolicyWarningModal {...defaultProps} />)
    expect(
      screen.getByText(
        /If any imported assignments have past due dates, they may receive automatic zeros/,
      ),
    ).toBeInTheDocument()
  })

  it('displays the mitigation message', () => {
    render(<MissingPolicyWarningModal {...defaultProps} />)
    expect(
      screen.getByText(
        /cancel and adjust due dates, or disable the missing policy in this course\./,
      ),
    ).toBeInTheDocument()
  })

  it('calls onCancel when Cancel button is clicked', async () => {
    const user = userEvent.setup()
    render(<MissingPolicyWarningModal {...defaultProps} />)
    await user.click(screen.getByTestId('cancel-button'))
    expect(defaultProps.onCancel).toHaveBeenCalledTimes(1)
  })

  it('calls onDisablePolicy when Disable Policy button is clicked', async () => {
    const user = userEvent.setup()
    render(<MissingPolicyWarningModal {...defaultProps} />)
    await user.click(screen.getByTestId('disable-policy-button'))
    expect(defaultProps.onDisablePolicy).toHaveBeenCalledTimes(1)
  })

  it('calls onImportAnyway when Import Anyway button is clicked', async () => {
    const user = userEvent.setup()
    render(<MissingPolicyWarningModal {...defaultProps} />)
    await user.click(screen.getByTestId('import-anyway-button'))
    expect(defaultProps.onImportAnyway).toHaveBeenCalledTimes(1)
  })

  it('disables all buttons when isDisabling is true', () => {
    render(<MissingPolicyWarningModal {...defaultProps} isDisabling={true} />)
    expect(screen.getByTestId('cancel-button')).toBeDisabled()
    expect(screen.getByTestId('disable-policy-button')).toBeDisabled()
    expect(screen.getByTestId('import-anyway-button')).toBeDisabled()
  })

  it('enables all buttons when isDisabling is false', () => {
    render(<MissingPolicyWarningModal {...defaultProps} isDisabling={false} />)
    expect(screen.getByTestId('cancel-button')).not.toBeDisabled()
    expect(screen.getByTestId('disable-policy-button')).not.toBeDisabled()
    expect(screen.getByTestId('import-anyway-button')).not.toBeDisabled()
  })

  describe('scenario-specific headings and messages', () => {
    it('displays destination scenario heading and message', () => {
      render(<MissingPolicyWarningModal {...defaultProps} scenario="destination" />)
      expect(
        screen.getByText('Warning: This course has Automatic Missing Policy enabled'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/importing into a course with Automatic Missing Policy enabled/),
      ).toBeInTheDocument()
      expect(screen.getByTestId('disable-policy-button')).toHaveTextContent('Disable Policy')
    })

    it('displays source scenario heading and message', () => {
      render(<MissingPolicyWarningModal {...defaultProps} scenario="source" />)
      expect(
        screen.getByText('Warning: The source course has Automatic Missing Policy enabled'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/importing from a course with Automatic Missing Policy enabled/),
      ).toBeInTheDocument()
      expect(screen.getByTestId('disable-policy-button')).toHaveTextContent("Don't Import Policy")
    })

    it('displays both scenario heading and message', () => {
      render(<MissingPolicyWarningModal {...defaultProps} scenario="both" />)
      expect(
        screen.getByText('Warning: Both courses have Automatic Missing Policy enabled'),
      ).toBeInTheDocument()
      expect(
        screen.getByText(/The source course's policy settings will be copied to your course/),
      ).toBeInTheDocument()
      expect(screen.getByTestId('disable-policy-button')).toHaveTextContent(
        'Disable & Skip Policy Import',
      )
    })
  })
})

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

import '../../../__tests__/mockedDependenciesShims'
import {fireEvent, screen} from '@testing-library/react'
import {renderComponent} from '../../../__tests__/renderingShims'
import {describe, expect, fn, it} from '../../../__tests__/testPlatformShims'
import {useResubmitDiscussionNotices} from '../../../dependenciesShims'
import {ResubmitDiscussionNoticesButton} from '../ResubmitDiscussionNoticesButton'

describe('ResubmitDiscussionNoticesButton', () => {
  const defaultProps = {
    assignmentId: '123',
    studentId: '456',
    size: 'small' as const,
  }

  beforeEach(() => {
    ;(useResubmitDiscussionNotices as any).mockClear?.()
  })

  it('renders button with correct text', () => {
    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
  })

  it('renders with small size', () => {
    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} size="small" />)
    expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
  })

  it('renders with medium size', () => {
    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} size="medium" />)
    expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
  })

  it('calls mutate when clicked', () => {
    const mockMutate = fn()
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: mockMutate,
      isIdle: true,
      isError: false,
      variables: undefined,
    })

    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const button = screen.getByText('Resubmit All Replies')
    fireEvent.click(button)

    expect(mockMutate).toHaveBeenCalled()
  })

  it('disables button when mutation is pending', () => {
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: fn(),
      isIdle: false,
      isError: false,
      variables: {assignmentId: '123', studentId: '456'},
    })

    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const buttonText = screen.getByText('Resubmit All Replies')
    const button = buttonText.closest('button')
    expect(button).toBeDisabled()
  })

  it('disables button after successful submission', () => {
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: fn(),
      isIdle: false,
      isError: false,
      variables: {assignmentId: '123', studentId: '456'},
    })

    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const buttonText = screen.getByText('Resubmit All Replies')
    const button = buttonText.closest('button')
    expect(button).toBeDisabled()
  })

  it('enables button when error occurs', () => {
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: fn(),
      isIdle: false,
      isError: true,
      variables: {assignmentId: '123', studentId: '456'},
    })

    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const buttonText = screen.getByText('Resubmit All Replies')
    const button = buttonText.closest('button')
    expect(button).not.toBeDisabled()
  })

  it('has correct id attribute', () => {
    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const buttonText = screen.getByText('Resubmit All Replies')
    const button = buttonText.closest('button')
    expect(button).toHaveAttribute('id', 'asset-processor-resubmit-discussion-notices')
  })

  it('does not disable button for different student', () => {
    ;(useResubmitDiscussionNotices as any).mockReturnValue({
      mutate: fn(),
      isIdle: false,
      isError: false,
      variables: {assignmentId: '123', studentId: '789'}, // Different student
    })

    renderComponent(<ResubmitDiscussionNoticesButton {...defaultProps} />)
    const buttonText = screen.getByText('Resubmit All Replies')
    const button = buttonText.closest('button')
    expect(button).not.toBeDisabled()
  })
})

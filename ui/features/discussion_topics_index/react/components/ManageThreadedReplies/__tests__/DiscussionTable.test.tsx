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
import {useManageThreadedRepliesStore} from '../../../hooks/useManageThreadedRepliesStore'
import DiscussionTable from '../DiscussionTable'

// Mock the store hook
jest.mock('../../../hooks/useManageThreadedRepliesStore')
const mockedUseManageThreadedRepliesStore = useManageThreadedRepliesStore as unknown as jest.Mock

describe('DiscussionTable', () => {
  const mockToggleSelectedDiscussions = jest.fn()
  const mockSetDiscussionState = jest.fn()
  const mockToggleSelectedDiscussion = jest.fn()
  const mockState = {
    showAlert: true,
    selectedDiscussions: [],
    discussionStates: {},
    isValid: false,
    toggleSelectedDiscussions: mockToggleSelectedDiscussions,
    setDiscussionState: mockSetDiscussionState,
    toggleSelectedDiscussion: mockToggleSelectedDiscussion,
  }

  beforeEach(() => {
    jest.clearAllMocks()
    mockedUseManageThreadedRepliesStore.mockImplementation(selector => selector(mockState))
  })

  const discussions = [
    {
      id: '1',
      isPublished: true,
      title: 'Discussion 1',
      lastReplyAt: '2023-01-01',
      isAssignment: false,
    },
    {id: '2', isPublished: false, title: 'Discussion 2', lastReplyAt: null, isAssignment: true},
  ]

  it('renders correctly with discussions', () => {
    render(<DiscussionTable mobileOnly={false} discussions={discussions} />)
    expect(screen.getByText('Discussion 1')).toBeInTheDocument()
    expect(screen.getByText('Discussion 2')).toBeInTheDocument()
    expect(
      screen.getByTestId('manage-threaded-replies-set-to-threaded-selected-button'),
    ).toBeInTheDocument()
    expect(
      screen.getByTestId('manage-threaded-replies-set-to-not-threaded-selected-button'),
    ).toBeInTheDocument()
  })

  it('renders "Select all" checkbox and handles selection', () => {
    const {rerender} = render(<DiscussionTable mobileOnly={false} discussions={discussions} />)
    const selectAllCheckbox = screen.getByLabelText('Select all')
    expect(selectAllCheckbox).toBeInTheDocument()

    fireEvent.click(selectAllCheckbox)
    expect(mockToggleSelectedDiscussions).toHaveBeenCalledWith(['1', '2'])

    mockedUseManageThreadedRepliesStore.mockImplementation(selector =>
      selector({
        ...mockState,
        selectedDiscussions: ['1', '2'],
      }),
    )

    rerender(<DiscussionTable mobileOnly={false} discussions={discussions} />)

    fireEvent.click(selectAllCheckbox)
    expect(mockToggleSelectedDiscussions).toHaveBeenLastCalledWith([])
  })

  it('handles "Set to Threaded" button click', () => {
    mockedUseManageThreadedRepliesStore.mockImplementation(selector =>
      selector({
        ...mockState,
        selectedDiscussions: ['1'],
      }),
    )

    render(<DiscussionTable mobileOnly={false} discussions={discussions} />)

    const threadedButton = screen.getByText('Set to Threaded')
    fireEvent.click(threadedButton)

    expect(mockSetDiscussionState).toHaveBeenCalledWith('1', 'threaded')
  })

  it('handles "Set to Not threaded" button click', () => {
    mockedUseManageThreadedRepliesStore.mockImplementation(selector =>
      selector({
        ...mockState,
        selectedDiscussions: ['2'],
      }),
    )

    render(<DiscussionTable mobileOnly={false} discussions={discussions} />)
    const notThreadedButton = screen.getByText('Set to Not threaded')
    fireEvent.click(notThreadedButton)

    expect(mockSetDiscussionState).toHaveBeenCalledWith('2', 'not_threaded')
  })

  it('toggles individual discussion selection', () => {
    render(<DiscussionTable mobileOnly={false} discussions={discussions} />)
    const discussionCheckbox = screen.getAllByLabelText('Select entry')[0]

    fireEvent.click(discussionCheckbox)
    expect(mockToggleSelectedDiscussion).toHaveBeenCalledWith('1')
  })
})

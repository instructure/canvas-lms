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
import DiscussionThreadedSelect from '../DiscussionThreadedSelect'

// Mock the store hook
jest.mock('../../../hooks/useManageThreadedRepliesStore')
const mockedUseManageThreadedRepliesStore = useManageThreadedRepliesStore as unknown as jest.Mock

describe('DiscussionThreadedSelect', () => {
  const mockSetDiscussionState = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
    mockedUseManageThreadedRepliesStore.mockImplementation(selector =>
      selector({
        discussionStates: {testId: 'not_set'},
        setDiscussionState: mockSetDiscussionState,
      }),
    )
  })

  it('renders without crashing', () => {
    render(<DiscussionThreadedSelect id="testId" />)
    expect(screen.getByTestId('discussion-threaded-select')).toBeInTheDocument()
  })

  it('displays the correct default option', () => {
    render(<DiscussionThreadedSelect id="testId" />)
    expect(screen.getByDisplayValue('-')).toBeInTheDocument()
  })

  it('opens the dropdown when clicked', () => {
    render(<DiscussionThreadedSelect id="testId" />)
    const select = screen.getByTestId('discussion-threaded-select')
    fireEvent.click(select)
    expect(screen.getByTestId('discussion-threaded-select-option-option2')).toBeInTheDocument()
    expect(screen.getByTestId('discussion-threaded-select-option-option3')).toBeInTheDocument()
  })

  it('calls setDiscussionState when a valid option is selected', () => {
    render(<DiscussionThreadedSelect id="testId" />)
    const select = screen.getByTestId('discussion-threaded-select')
    fireEvent.click(select)
    const option = screen.getByTestId('discussion-threaded-select-option-option2')
    fireEvent.click(option)
    expect(mockSetDiscussionState).toHaveBeenCalledWith('testId', 'threaded')
  })

  it('does not call setDiscussionState when a disabled option is selected', () => {
    render(<DiscussionThreadedSelect id="testId" />)
    const select = screen.getByTestId('discussion-threaded-select')
    fireEvent.click(select)
    const disabledOption = screen.getByTestId('discussion-threaded-select-option-option1')
    fireEvent.click(disabledOption)
    expect(mockSetDiscussionState).not.toHaveBeenCalled()
  })
})

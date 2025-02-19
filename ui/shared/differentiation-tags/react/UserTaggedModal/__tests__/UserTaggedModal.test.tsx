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
import UserTaggedModal from '../UserTaggedModal'
import type {UserTaggedModalProps} from '../UserTaggedModal'
import {useUserTags} from '../../hooks/useUserTags'

jest.mock('../../hooks/useUserTags')
const mockuseUserTags = useUserTags as jest.Mock
describe('UserTaggedModal', () => {
  const defaultProps: UserTaggedModalProps = {
    isOpen: true,
    courseId: 1,
    userId: 2,
    userName: 'user',
    onClose: jest.fn(),
  }

  const renderComponent = (mockReturn = {}, props = {}) => {
    const defaultMock = {
      data: [{id: 1, name: 'test group', groupCategoryName: 'test category'}],
      isLoading: false,
      error: null,
    }
    mockuseUserTags.mockReturnValue({...defaultMock, ...mockReturn})
    render(<UserTaggedModal {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('Shows the modal if isOpen is true', () => {
    renderComponent()
    expect(screen.queryByTestId('user-tag-modal')).toBeInTheDocument()
  })

  it('does not show the modal when isOpen is false', () => {
    renderComponent({}, {isOpen: false})
    expect(screen.queryByTestId('user-tag-modal')).not.toBeInTheDocument()
  })

  it('shows loading spinner when isLoading is true', () => {
    renderComponent({isLoading: true})
    expect(screen.getByTitle('Loading...')).toBeInTheDocument()
  })

  it('shows error message when there is an error', () => {
    const error = new Error('Failed to fetch')
    renderComponent({error})
    expect(screen.getByText(/An error occurred while loading the Modal:/)).toBeInTheDocument()
    expect(screen.getByText(/Failed to fetch/)).toBeInTheDocument()
  })

  it('shows message when there is not any tag for that user', () => {
    renderComponent({data: []})
    expect(screen.getByText(/No tags available for this user/)).toBeInTheDocument()
  })

  it('displays differentiation tag categories when data is available', () => {
    const mockData = [
      {id: 1, name: 'Macroeconomics', groupCategoryName: 'Reading Groups'},
      {id: 2, name: 'Microeconomics', groupCategoryName: 'Reading Groups'},
    ]
    renderComponent({data: mockData})
    expect(screen.getByText('Reading Groups | Macroeconomics')).toBeInTheDocument()
    expect(screen.getByText('Reading Groups | Microeconomics')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    renderComponent()
    const closeButton = screen.getByRole('button', {
      name: 'Close the user tags modal',
      hidden: true,
    })

    await userEvent.click(closeButton)
    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('shows the delete warning modal when click the tag', async () => {
    const mockData = [
      {id: 1, name: 'Macroeconomics', groupCategoryName: 'Reading Groups'},
      {id: 2, name: 'Microeconomics', groupCategoryName: 'Reading Groups'},
    ]
    renderComponent({data: mockData})
    expect(screen.getByText('Reading Groups | Macroeconomics')).toBeInTheDocument()
    expect(screen.getByText('Reading Groups | Microeconomics')).toBeInTheDocument()
    const tagBtn = screen.queryByTestId('user-tag-1')
    if (tagBtn) await userEvent.click(tagBtn)
    expect(screen.getByText(/Deleting this tag preserves past assignments/i)).toBeInTheDocument()
  })
})

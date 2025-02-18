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
import userEvent from '@testing-library/user-event'
import UserTaggedModal from '../UserTaggedModal'
import type {UserTaggedModalProps} from '../UserTaggedModal'
import {useUserTags} from '../../hooks/useUserTags'
import {useDeleteTagMembership} from '../../hooks/useDeleteTagMembership'
import MessageBus from '@canvas/util/MessageBus'

jest.mock('../../hooks/useUserTags')
jest.mock('../../hooks/useDeleteTagMembership')
jest.mock('@canvas/util/MessageBus', () => ({
  trigger: jest.fn(),
}))

const mockuseUserTags = useUserTags as jest.Mock
const mockuseDeleteTagMembership = useDeleteTagMembership as jest.Mock
describe('UserTaggedModal', () => {
  const defaultProps: UserTaggedModalProps = {
    isOpen: true,
    courseId: 1,
    userId: 2,
    userName: 'user',
    onClose: jest.fn(),
  }
  const mutateMock = jest.fn()
  const renderComponent = (mockReturn = {}, props = {}, mutationMockReturn = {}) => {
    const defaultMock = {
      data: [{id: 1, name: 'test group', groupCategoryName: 'test category'}],
      isLoading: false,
      error: null,
    }
    const defaultMutationMock = { mutate: mutateMock, isLoading: false, isSuccess: true, isError: false, error: null}
    mockuseUserTags.mockReturnValue({...defaultMock, ...mockReturn})
    mockuseDeleteTagMembership.mockReturnValue({...defaultMutationMock, ...mutationMockReturn})
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
    expect(
      screen.getByText(/Removing the tag from a student preserves past assignments/i),
    ).toBeInTheDocument()
  })

  it('calls mutate when removing a tag from the user', async () =>{
    const mockData = [
      {id: 1, name: 'Macroeconomics', groupCategoryName: 'Reading Groups'},
      {id: 2, name: 'Microeconomics', groupCategoryName: 'Reading Groups'},
    ]
    renderComponent({data:mockData})
    expect(screen.getByText('Reading Groups | Macroeconomics')).toBeInTheDocument()
    expect(screen.getByText('Reading Groups | Microeconomics')).toBeInTheDocument()
    const tagBtn = screen.queryByTestId('user-tag-1')
    if(tagBtn)
        await userEvent.click(tagBtn)
    expect(
      screen.getByText(/Removing the tag from a student preserves past assignments/i),
    ).toBeInTheDocument()
    fireEvent.click(screen.getByText('Confirm'))

    expect(mutateMock).toHaveBeenCalled()
    expect(screen.getByText(/Tag removed successfully/)).toBeInTheDocument()
  })

  it('shows an Alert with error description when mutation fails', async () =>{
    const mockData = [
      {id: 1, name: 'Macroeconomics', groupCategoryName: 'Reading Groups'},
      {id: 2, name: 'Microeconomics', groupCategoryName: 'Reading Groups'},
    ]
    const error = new Error('Forbidden, user does not have permission')

    renderComponent({data:mockData},{},{isSuccess: false, isError: true, error: error})
    expect(screen.getByText('Reading Groups | Macroeconomics')).toBeInTheDocument()
    expect(screen.getByText('Reading Groups | Microeconomics')).toBeInTheDocument()
    const tagBtn = screen.queryByTestId('user-tag-1')
    if(tagBtn)
        await userEvent.click(tagBtn)
    expect(
      screen.getByText(/Removing the tag from a student preserves past assignments/i),
    ).toBeInTheDocument()
    fireEvent.click(screen.getByText('Confirm'))

    expect(mutateMock).toHaveBeenCalled()
    expect(screen.getByText(/Error: Forbidden, user does not have permission/)).toBeInTheDocument()
  })

  it('it sends a message to RoosterView to remove user tag icon when all tags are removed', async () =>{
    renderComponent({data:[]})
    expect(MessageBus.trigger).toHaveBeenCalledWith('removeUserTagIcon', { userId: 2 });
    
  })
})

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render as rawRender, fireEvent, waitFor} from '@testing-library/react'
import GroupRemoveModal from '../GroupRemoveModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {removeOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/outcomes/graphql/Management')

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

class CustomError extends Error {
  constructor(message) {
    super()
    this.response = {
      data: message,
    }
  }
}

describe('GroupRemoveModal', () => {
  let onCloseHandlerMock
  let onSuccessMock
  const defaultProps = (props = {}) => ({
    groupId: '123',
    groupTitle: 'Fancy group',
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onSuccess: onSuccessMock,
    ...props,
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    onSuccessMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (children, {contextType = 'Account', contextId = '1'} = {}) => {
    return rawRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    )
  }

  it('shows modal if isOpen prop true', () => {
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    expect(getByText('Remove Group?')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = render(<GroupRemoveModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Remove Group?')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Remove button click', async () => {
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Group'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', async () => {
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', async () => {
    const {getAllByText} = render(<GroupRemoveModal {...defaultProps()} />)
    const closeBtn = getAllByText('Close')[getAllByText('Close').length - 1]
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('renders component with proper text for Account context', () => {
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    expect(
      getByText(
        'Are you sure that you want to remove this group and all of its content from your account?'
      )
    ).toBeInTheDocument()
  })

  it('renders component with proper text for Course context', () => {
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />, {
      contextType: 'Course',
    })
    expect(
      getByText(
        'Are you sure that you want to remove this group and all of its content from your course?'
      )
    ).toBeInTheDocument()
  })

  it('displays flash confirmation with proper message and calls onSuccess if delete request succeeds', async () => {
    removeOutcomeGroup.mockReturnValue(
      Promise.resolve({status: 200, data: {id: 2, parent_outcome_group: {id: 1}}})
    )
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Group'))
    expect(removeOutcomeGroup).toHaveBeenCalledWith('Account', '1', '123')
    await waitFor(() => {
      expect(onSuccessMock).toHaveBeenCalled()
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'This group was successfully removed.',
        type: 'success',
      })
    })
  })

  it('displays flash error if delete request fails', async () => {
    removeOutcomeGroup.mockReturnValue(Promise.reject(new Error('Network error')))
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Group'))
    expect(removeOutcomeGroup).toHaveBeenCalledWith('Account', '1', '123')
    await waitFor(() => {
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing this group. Please try again.',
        type: 'error',
      })
    })
  })

  it('displays proper flash error message if delete request fails due to aligned outcome', async () => {
    removeOutcomeGroup.mockReturnValue(
      Promise.reject(new CustomError('cannot be deleted because it is aligned to contents'))
    )
    const {getByText} = render(<GroupRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Group'))
    expect(removeOutcomeGroup).toHaveBeenCalledWith('Account', '1', '123')
    await waitFor(() => {
      expect(showFlashAlert).toHaveBeenCalledWith({
        message:
          'An error occurred while removing this group: "Fancy group" contains one or more Outcomes that are currently aligned to content.',
        type: 'error',
      })
    })
  })
})

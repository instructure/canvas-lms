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
import {render as realRender, fireEvent, wait} from '@testing-library/react'
import EditGroupModal from '../EditGroupModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateOutcomeGroup} from '@canvas/outcomes/graphql/Management'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('@canvas/outcomes/graphql/Management')

describe('EditGroupModal', () => {
  let onCloseHandlerMock
  const contextType = 'Account'
  const contextId = '1'
  const group = {
    _id: '2',
    title: 'Grade 2',
    description: 'This is the Amazing Group 2'
  }
  const defaultProps = (props = {}) => ({
    outcomeGroup: group,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  const render = (children = {}) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    )
  }

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  it('renders component with the content', () => {
    const {getByText} = render(<EditGroupModal {...defaultProps()} />)
    expect(getByText('Edit Group')).toBeInTheDocument()
    expect(getByText('This is the Amazing Group 2')).toBeInTheDocument()
  })

  it('shows modal if open prop true', () => {
    const {getByText} = render(<EditGroupModal {...defaultProps()} />)
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', () => {
    const {queryByText} = render(<EditGroupModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', () => {
    const {getByText} = render(<EditGroupModal {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Cancel button click', () => {
    const {getByText} = render(<EditGroupModal {...defaultProps()} />)
    const cancelBtn = getByText('Cancel')
    fireEvent.click(cancelBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('setting blank title disables Save button and displays error', () => {
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: ''}})
    expect(getByText('Save')).not.toHaveAttribute('disabled')
    expect(getByText('Missing required title')).toBeInTheDocument()
  })

  it('setting title with more than 255 characters disables Save button and displays error', () => {
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Grade 2')
    const text = 'x'.repeat(256)
    fireEvent.change(titleField, {target: {value: text}})
    expect(getByText('Save')).not.toHaveAttribute('disabled')
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
  })

  it('updates the group and closes the modal on Save button click', async () => {
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    updateOutcomeGroup.mockReturnValue(Promise.resolve({status: 200}))
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    fireEvent.click(getByText('Save'))
    expect(updateOutcomeGroup).toHaveBeenCalledWith(contextType, contextId, {
      ...group,
      title: 'Grade 2 edited'
    })
    await wait(() => {
      expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      expect(showFlashAlert).toHaveBeenCalledWith({
        type: 'success',
        message: 'The group Grade 2 edited was successfully updated.'
      })
    })
  })

  it('displays an error if an exception is produced on Save button click', async () => {
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    updateOutcomeGroup.mockReturnValue(Promise.reject(new Error('Server is busy')))
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    fireEvent.click(getByText('Save'))
    expect(updateOutcomeGroup).toHaveBeenCalledWith(contextType, contextId, {
      ...group,
      title: 'Grade 2 edited'
    })
    await wait(() => {
      expect(onCloseHandlerMock).not.toHaveBeenCalled()
      expect(showFlashAlert).toHaveBeenCalledWith({
        type: 'error',
        message: 'An error occurred while updating the group: Server is busy'
      })
    })
  })
})

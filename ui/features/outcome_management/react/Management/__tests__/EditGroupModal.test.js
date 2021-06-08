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
import {render as realRender, fireEvent, act} from '@testing-library/react'
import EditGroupModal from '../EditGroupModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import useRCE from '../../hooks/useRCE'

jest.mock('../../hooks/useRCE')
jest.mock('@canvas/alerts/react/FlashAlert')
jest.mock('@canvas/outcomes/graphql/Management')
jest.useFakeTimers()

describe('EditGroupModal', () => {
  let onCloseHandlerMock, rceValue
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
    rceValue = 'Updated description'
    useRCE.mockReturnValue([() => {}, () => rceValue, null, null, null])
    onCloseHandlerMock = jest.fn()
    window.ENV.FEATURES = {}
  })

  it('renders component with the content', async () => {
    const {getByText} = render(<EditGroupModal {...defaultProps()} />)
    expect(getByText('Edit Group')).toBeInTheDocument()
  })

  it('updates the group, closes the modal', async () => {
    updateOutcomeGroup.mockReturnValue(Promise.resolve({status: 200}))
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcomeGroup).toHaveBeenCalledWith(contextType, contextId, group._id, {
      title: 'Grade 2 edited',
      description: 'Updated description'
    })
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: 'The group Grade 2 edited was successfully updated.'
    })
  })

  it('updates the group with blank attributes', async () => {
    rceValue = ''
    updateOutcomeGroup.mockReturnValue(Promise.resolve({status: 200}))
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcomeGroup).toHaveBeenCalledWith(contextType, contextId, group._id, {
      title: 'Grade 2 edited',
      description: ''
    })
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: 'The group Grade 2 edited was successfully updated.'
    })
  })

  it('reset the form on modal close', () => {
    const {getByDisplayValue, rerender} = render(<EditGroupModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    rerender(<EditGroupModal {...defaultProps({isOpen: false})} />)
    rerender(<EditGroupModal {...defaultProps({isOpen: true})} />)
    expect(getByDisplayValue('Grade 2')).toBeInTheDocument()
  })

  it('displays an error if an exception is produced on submission', async () => {
    const {getByDisplayValue, getByText} = render(<EditGroupModal {...defaultProps()} />)
    updateOutcomeGroup.mockReturnValue(Promise.reject(new Error('Server is busy')))
    const titleField = getByDisplayValue('Grade 2')
    fireEvent.change(titleField, {target: {value: 'Grade 2 edited'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcomeGroup).toHaveBeenCalledWith(contextType, contextId, group._id, {
      title: 'Grade 2 edited',
      description: 'Updated description'
    })
    expect(onCloseHandlerMock).not.toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message: 'An error occurred while updating the group: Server is busy'
    })
  })
})

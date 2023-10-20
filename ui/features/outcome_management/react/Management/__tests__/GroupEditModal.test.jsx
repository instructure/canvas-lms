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
import {MockedProvider} from '@apollo/react-testing'
import {createCache} from '@canvas/apollo'
import GroupEditModal from '../GroupEditModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateOutcomeGroupMock} from '@canvas/outcomes/mocks/Management'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('GroupEditModal', () => {
  let cache
  let onCloseHandlerMock
  const group = {
    _id: '100',
    title: 'Group title',
    description: 'Group description',
  }
  const defaultProps = (props = {}) => ({
    outcomeGroup: group,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props,
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      mocks = [updateOutcomeGroupMock({description: group.description})],
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  beforeEach(() => {
    cache = createCache()
    onCloseHandlerMock = jest.fn()
    window.ENV.FEATURES = {}
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component with content', async () => {
    const {getByText} = render(<GroupEditModal {...defaultProps()} />)
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Edit Group')).toBeInTheDocument()
  })

  it('updates group and shows flash confirmation', async () => {
    const {getByDisplayValue, getByText} = render(<GroupEditModal {...defaultProps()} />, {
      mocks: [
        updateOutcomeGroupMock({
          vendorGuid: null,
          parentOutcomeGroupId: null,
          description: group.description,
        }),
      ],
    })
    await act(async () => jest.runOnlyPendingTimers())
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: '"Updated title" was successfully updated.',
    })
  })

  it('updates only part of group attributes and shows flash confirmation', async () => {
    const {getByDisplayValue, getByText} = render(<GroupEditModal {...defaultProps()} />, {
      mocks: [
        updateOutcomeGroupMock({
          vendorGuid: null,
          parentOutcomeGroupId: null,
          description: group.description,
        }),
      ],
    })
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'success',
      message: '"Updated title" was successfully updated.',
    })
  })

  it('resets the form on modal close', () => {
    const {getByDisplayValue, rerender} = render(<GroupEditModal {...defaultProps()} />)
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    rerender(<GroupEditModal {...defaultProps({isOpen: false})} />)
    rerender(<GroupEditModal {...defaultProps({isOpen: true})} />)
    expect(getByDisplayValue('Group title')).toBeInTheDocument()
  })

  it('shows custom error flash message when updating group fails', async () => {
    const {getByDisplayValue, getByText} = render(<GroupEditModal {...defaultProps()} />, {
      mocks: [
        updateOutcomeGroupMock({
          vendorGuid: null,
          parentOutcomeGroupId: null,
          failResponse: true,
          description: group.description,
        }),
      ],
    })
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message: 'An error occurred while editing this group. Please try again.',
    })
  })

  it('shows flash error message when updating group mutation fails', async () => {
    const {getByDisplayValue, getByText} = render(<GroupEditModal {...defaultProps()} />, {
      mocks: [
        updateOutcomeGroupMock({
          vendorGuid: null,
          parentOutcomeGroupId: null,
          failMutation: true,
          description: group.description,
        }),
      ],
    })
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message: 'An error occurred while editing this group. Please try again.',
    })
  })

  it('shows default error flash message when updating group fails and error message is empty', async () => {
    const {getByDisplayValue, getByText} = render(<GroupEditModal {...defaultProps()} />, {
      mocks: [
        updateOutcomeGroupMock({
          vendorGuid: null,
          parentOutcomeGroupId: null,
          failMutationNoErrMsg: true,
          description: group.description,
        }),
      ],
    })
    const titleField = getByDisplayValue('Group title')
    fireEvent.change(titleField, {target: {value: 'Updated title'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalled()
    expect(showFlashAlert).toHaveBeenCalledWith({
      type: 'error',
      message: 'An error occurred while editing this group. Please try again.',
    })
  })
})

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
import $ from 'jquery'
import React from 'react'
import {MockedProvider} from '@apollo/react-testing'
import {render as rtlRender, act, fireEvent} from '@testing-library/react'
import MoveModal from '../MoveModal'
import {accountMocks, groupMocks} from './mocks'
import OutcomesContext from 'jsx/outcomes/contexts/OutcomesContext'
import {createCache} from 'jsx/canvas-apollo'

jest.useFakeTimers()

describe('MoveModal', () => {
  let onCloseHandlerMock
  let cache

  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    title: 'Outcome Group',
    type: 'outcome',
    contextType: 'Account',
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '1', mocks = accountMocks({childGroupsCount: 0})} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders component with Group title', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Move "Outcome Group"')).toBeInTheDocument()
  })

  it('shows modal if open prop true', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', async () => {
    const {queryByText} = render(<MoveModal {...defaultProps({isOpen: false})} />)
    await act(async () => jest.runAllTimers())
    expect(queryByText('Cancel')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Cancel button click', async () => {
    const {getByText} = render(<MoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Cancel')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<MoveModal {...defaultProps({contextType: 'Account'})} />, {
      contextType: 'Account',
      contextId: '1',
      mocks: [...accountMocks({childGroupsCount: 2}), ...groupMocks({groupId: 100})]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays an error on failed request for account outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<MoveModal {...defaultProps({contextType: 'Account'})} />, {
      contextType: 'Account',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading account outcomes.')
    expect(getByText(/account/)).toBeInTheDocument()
  })

  it('displays an error on failed request for course outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<MoveModal {...defaultProps({contextType: 'Course'})} />, {
      contextType: 'Course',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading course outcomes.')
    expect(getByText(/course/)).toBeInTheDocument()
  })
})

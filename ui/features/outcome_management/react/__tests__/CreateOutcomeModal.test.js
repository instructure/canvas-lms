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
import {act, render as rtlRender, fireEvent, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {createCache} from '@canvas/apollo'
import {within} from '@testing-library/dom'
import CreateOutcomeModal from '../CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {accountMocks, smallOutcomeTree} from '@canvas/outcomes/mocks/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import axios from '@canvas/axios'

jest.mock('@canvas/axios')
jest.mock('@canvas/rce/RichContentEditor')
jest.useFakeTimers()

describe('CreateOutcomeModal', () => {
  let onCloseHandlerMock
  let cache

  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
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

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows modal if isOpen prop true', async () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Create Outcome')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', async () => {
    const {queryByText} = render(<CreateOutcomeModal {...defaultProps({isOpen: false})} />)
    await act(async () => jest.runAllTimers())
    expect(queryByText('Create Outcome')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Create button click', async () => {
    const {getByLabelText, getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Create'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', async () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', async () => {
    const {getByRole} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.click(within(getByRole('dialog')).getByText('Close'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('does not show error message below Name field on initial load and disables Create button', async () => {
    const {getByText, queryByText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(queryByText('Cannot be blank')).not.toBeInTheDocument()
  })

  it('shows error message below Name field if no name after user makes changes to name and disables Create button', async () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: '123'}})
    fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name includes only spaces and disables Create button', async () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name > 255 characters and disables Create button', async () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
  })

  it('shows error message below displayName field if displayName > 255 characters and disables Create button', async () => {
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('enables Create button when name is entered and group is selected', async () => {
    const {getByLabelText, getByText, getByRole} = render(
      <CreateOutcomeModal {...defaultProps()} />,
      {
        mocks: [...smallOutcomeTree('Account')]
      }
    )
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Account folder 0'))
    expect(within(getByRole('dialog')).getByText('Create').closest('button')).not.toHaveAttribute(
      'disabled'
    )
  })

  it('displays an error on failed request for account outcome groups', async () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
  })

  it('displays an error on failed request for course outcome groups', async () => {
    const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      contextType: 'Course',
      contextId: '2',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
  })

  it('displays flash confirmation with proper message if create request succeeds', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    axios.post.mockResolvedValue({status: 200})
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
    fireEvent.click(getByText('Account folder 0'))
    fireEvent.click(getByText('Create'))
    await act(async () => jest.runAllTimers())
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Outcome "Outcome 123" was successfully created',
        type: 'success'
      })
    })
  })

  it('displays flash error if create request fails', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    axios.post.mockRejectedValueOnce(new Error('Network error'))
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
    fireEvent.click(getByText('Account folder 0'))
    fireEvent.click(getByText('Create'))
    await act(async () => jest.runAllTimers())
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while creating this outcome: Network error',
        type: 'error'
      })
    })
  })

  it('displays flash error with generic error message if create request fails and err.message not provided', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    axios.post.mockRejectedValueOnce(new Error())
    const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree('Account')]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
    fireEvent.click(getByText('Account folder 0'))
    fireEvent.click(getByText('Create'))
    await act(async () => jest.runAllTimers())
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while creating this outcome.',
        type: 'error'
      })
    })
  })
})

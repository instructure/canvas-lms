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
import {render, fireEvent, waitFor, act} from '@testing-library/react'
import {within} from '@testing-library/dom'
import OutcomeEditModal from '../OutcomeEditModal'
import {updateOutcome} from '../api'
import * as FlashAlert from '../../../shared/FlashAlert'

jest.mock('../api')
jest.useFakeTimers()

describe('OutcomeEditModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    outcome: {
      _id: '1',
      title: 'Outcome',
      description: 'Outcome description',
      displayName: 'Friendly outcome name'
    },
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows modal if isOpen prop true', () => {
    const {getByText} = render(<OutcomeEditModal {...defaultProps()} />)
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = render(<OutcomeEditModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('disables Save button if content not changed', () => {
    const {getByText} = render(<OutcomeEditModal {...defaultProps()} />)
    expect(getByText('Save').closest('button')).toHaveAttribute('disabled')
  })

  it('calls onCloseHandler on Save button click', () => {
    const {getByLabelText, getByText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Save'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', () => {
    const {getByRole} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.click(within(getByRole('dialog')).getByText('Close'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('shows error message below Name field if no name', () => {
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name includes only spaces', () => {
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name > 255 characters', () => {
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
  })

  it('shows error message below displayName field if displayName > 255 characters', () => {
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
  })

  it('updates only outcome name if only name is changed', async () => {
    updateOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcome).toHaveBeenCalledWith('1', {title: 'Updated name'})
  })

  it('updates only outcome description if only description is changed', async () => {
    updateOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Description'), {target: {value: 'Updated description'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcome).toHaveBeenCalledWith('1', {description: 'Updated description'})
  })

  it('updates only outcome display name if only display name is changed', async () => {
    updateOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Updated friendly name'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcome).toHaveBeenCalledWith('1', {display_name: 'Updated friendly name'})
  })

  it('displays flash confirmation with proper message if update request succeeds', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    updateOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcome).toHaveBeenCalledWith('1', {
      title: 'Outcome 123'
    })
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'This outcome was successfully updated.',
        type: 'success'
      })
    })
  })

  it('displays flash error if update request fails', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    updateOutcome.mockReturnValue(Promise.reject(new Error('Network error')))
    const {getByText, getByLabelText} = render(<OutcomeEditModal {...defaultProps()} />)
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runAllTimers())
    expect(updateOutcome).toHaveBeenCalledWith('1', {
      title: 'Outcome 123'
    })
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while updating this outcome: Network error',
        type: 'error'
      })
    })
  })
})

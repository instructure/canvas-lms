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
import {within} from '@testing-library/dom'
import OutcomeEditModal from '../OutcomeEditModal'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  updateOutcomeMocks,
  setFriendlyDescriptionOutcomeMock
} from '@canvas/outcomes/mocks/Management'

jest.useFakeTimers()

describe('OutcomeEditModal', () => {
  let onCloseHandlerMock
  let showFlashAlertSpy

  const outcome = {
    _id: '1',
    title: 'Outcome',
    description: 'Outcome description',
    displayName: 'Friendly outcome name',
    contextType: 'Account',
    contextId: '1'
  }

  const defaultProps = (props = {}) => ({
    outcome,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  const renderWithProvider = ({
    overrides = {},
    failResponse = false,
    failMutation = false.message,
    env = {
      contextType: 'Account',
      contextId: '1',
      friendlyDescriptionFF: true
    },
    mockOverrides = []
  } = {}) => {
    const mocks = [
      setFriendlyDescriptionOutcomeMock({
        failResponse,
        failMutation
      }),
      ...updateOutcomeMocks({description: outcome.description}),
      ...mockOverrides
    ]

    return render(
      <OutcomesContext.Provider value={{env}}>
        <MockedProvider mocks={mocks}>
          <OutcomeEditModal {...defaultProps()} {...overrides} />
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  const render = (children, mocks = []) => {
    return realRender(
      <MockedProvider addTypename={false} mocks={mocks}>
        {children}
      </MockedProvider>
    )
  }

  it('shows modal if isOpen prop true', () => {
    const {getByText} = renderWithProvider()
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = renderWithProvider({overrides: {isOpen: false}})
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Save button click', async () => {
    const {getByLabelText, getByText} = renderWithProvider()
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Save'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = renderWithProvider()
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', () => {
    const {getByRole} = renderWithProvider()
    fireEvent.click(within(getByRole('dialog')).getByText('Close'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('shows error message below Name field if no name and disables Save button', () => {
    const {getByText, getByLabelText} = renderWithProvider()
    fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
    expect(getByText('Save').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name includes only spaces and disables Save button', () => {
    const {getByText, getByLabelText} = renderWithProvider()
    fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
    expect(getByText('Save').closest('button')).toHaveAttribute('disabled')
    expect(getByText('Cannot be blank')).toBeInTheDocument()
  })

  it('shows error message below Name field if name > 255 characters and disables Save button', () => {
    const {getByText, getByLabelText} = renderWithProvider()
    fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Save').closest('button')).toHaveAttribute('disabled')
  })

  it('shows error message below displayName field if displayName > 255 characters and disables Save button', () => {
    const {getByText, getByLabelText} = renderWithProvider()
    fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
    expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    expect(getByText('Save').closest('button')).toHaveAttribute('disabled')
  })

  it('Shows forms elements when editing in same context', () => {
    const {getByTestId, queryByTestId} = renderWithProvider()
    expect(getByTestId('name-input')).toBeInTheDocument()
    expect(getByTestId('display-name-input')).toBeInTheDocument()
    expect(getByTestId('friendly-description-input')).toBeInTheDocument()
    expect(queryByTestId('readonly-description')).not.toBeInTheDocument()
  })

  it('Hides forms elements when editing in different context', () => {
    const {getByTestId, queryByTestId} = renderWithProvider({
      env: {contextType: 'Course', contextId: '1', friendlyDescriptionFF: true}
    })
    expect(queryByTestId('name-input')).not.toBeInTheDocument()
    expect(queryByTestId('display-name-input')).not.toBeInTheDocument()
    expect(queryByTestId('description-input')).not.toBeInTheDocument()
    expect(getByTestId('friendly-description-input')).toBeInTheDocument()
    expect(getByTestId('readonly-description')).toBeInTheDocument()
  })

  describe('updates the outcome', () => {
    it('displays flash confirmation with proper message if update request succeeds', async () => {
      const mocks = updateOutcomeMocks({description: 'Updated description'})
      const {getByText, getByDisplayValue, getByLabelText} = renderWithProvider({
        mockOverrides: mocks
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
      fireEvent.change(getByDisplayValue('Outcome description'), {
        target: {value: 'Updated description'}
      })
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Updated name" was successfully updated.',
        type: 'success'
      })
    })

    it('displays flash error if update request fails', async () => {
      const {getByText, getByLabelText} = renderWithProvider({
        overrides: {outcome: {...outcome, _id: '2'}}
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while editing this outcome. Please try again.',
        type: 'error'
      })
    })
  })

  describe('updates the friendly description', () => {
    it('updates only friendly description if only friendly description is changed', async () => {
      const {getByText, getByLabelText} = renderWithProvider()
      fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
        target: {value: 'Updated friendly description'}
      })
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Outcome" was successfully updated.',
        type: 'success'
      })
    })

    it('handles friendly description update failure', async () => {
      const {getByText, getByLabelText} = renderWithProvider({failResponse: true})
      fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
        target: {value: 'Updated friendly description'}
      })
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while editing this outcome. Please try again.',
        type: 'error'
      })
    })

    it('shows error message below friendly description field if friendly description > 255 characters', () => {
      const {getByText, getByLabelText} = renderWithProvider()
      fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
        target: {value: 'a'.repeat(256)}
      })
      expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    })
  })

  describe('with Friendly Description Feature Flag disabled', () => {
    it('does not display Friendly Description field in modal', async () => {
      const {queryByLabelText} = renderWithProvider({
        env: {contextType: 'Account', contextId: '1', friendlyDescriptionFF: false}
      })
      await act(async () => jest.runOnlyPendingTimers())
      expect(
        queryByLabelText('Friendly description (for parent/student display)')
      ).not.toBeInTheDocument()
    })

    it('does not call friendly description mutation when updating outcome', async () => {
      const {getByText, getByLabelText} = renderWithProvider({
        env: {contextType: 'Account', contextId: '1', friendlyDescriptionFF: false},
        // mock setFriendlyDescription mutation to throw an error
        failResponse: true
      })
      fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runOnlyPendingTimers())
      // if setFriendlyDescription mutation is called the expectation below will fail
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Updated name" was successfully updated.',
        type: 'success'
      })
    })
  })
})

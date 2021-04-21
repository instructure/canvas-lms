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
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {
  updateOutcomeMocks,
  setFriendlyDescriptionOutcomeMock
} from '@canvas/outcomes/mocks/Management'

jest.mock('@canvas/rce/RichContentEditor')
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
    contextId: 1
  }

  const defaultProps = (props = {}) => ({
    outcome,
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    RichContentEditor.callOnRCE = jest.fn()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
  })

  const renderWithProvider = ({
    overrides = {},
    failResponse = false,
    failMutation = false.message,
    env = {
      contextType: 'Account',
      contextId: '1'
    }
  } = {}) => {
    const mocks = [
      setFriendlyDescriptionOutcomeMock({
        failResponse,
        failMutation
      }),
      ...updateOutcomeMocks()
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

  it('calls onCloseHandler on Save button click', () => {
    const {getByLabelText, getByText} = renderWithProvider()
    fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
    fireEvent.click(getByText('Save'))
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
    const {getByTestId} = renderWithProvider()
    expect(getByTestId('name-input')).toBeInTheDocument()
    expect(getByTestId('display-name-input')).toBeInTheDocument()
    expect(getByTestId('description-input')).toBeInTheDocument()
    expect(getByTestId('alternate-description-input')).toBeInTheDocument()
  })

  it('Hides forms elements when editing in different context', () => {
    const {queryByTestId} = renderWithProvider({env: {contextType: 'Course', contextId: '1'}})
    expect(queryByTestId('name-input')).not.toBeInTheDocument()
    expect(queryByTestId('display-name-input')).not.toBeInTheDocument()
    expect(queryByTestId('description-input')).not.toBeInTheDocument()
    expect(queryByTestId('alternate-description-input')).toBeInTheDocument()
  })

  describe('updates the outcome', () => {
    it('displays flash confirmation with proper message if update request succeeds', async () => {
      RichContentEditor.callOnRCE.mockReturnValue('Updated description')
      const {getByText, getByLabelText} = renderWithProvider()
      await act(async () => jest.runAllTimers())
      fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'This outcome was successfully updated.',
        type: 'success'
      })
    })

    it('displays flash error if update request fails', async () => {
      RichContentEditor.callOnRCE.mockReturnValue('Updated description')
      const {getByText, getByLabelText} = renderWithProvider({
        overrides: {outcome: {...outcome, _id: '2'}}
      })
      await act(async () => jest.runAllTimers())
      fireEvent.change(getByLabelText('Name'), {target: {value: 'Updated name'}})
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: "An error occurred while updating this outcome: GraphQL error: can't be blank.",
        type: 'error'
      })
    })
  })

  describe('updates the alternate description', () => {
    it('updates only alternate description if only alternate description is changed', async () => {
      const {getByText, getByLabelText} = renderWithProvider()
      fireEvent.change(getByLabelText('Alternative description (for parent/student display)'), {
        target: {value: 'Updated alternate description'}
      })
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'This outcome was successfully updated.',
        type: 'success'
      })
    })

    it('handles altenate description update failure', async () => {
      const {getByText, getByLabelText} = renderWithProvider({failResponse: true})
      fireEvent.change(getByLabelText('Alternative description (for parent/student display)'), {
        target: {value: 'Updated alternate description'}
      })
      fireEvent.click(getByText('Save'))
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred while updating this outcome: GraphQL error: mutation failed.',
        type: 'error'
      })
    })

    it('shows error message below alternate description field if alternate description > 255 characters', () => {
      const {getByText, getByLabelText} = renderWithProvider()
      fireEvent.change(getByLabelText('Alternative description (for parent/student display)'), {
        target: {value: 'a'.repeat(256)}
      })
      expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
    })
  })
})

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
import OutcomeRemoveModal from '../OutcomeRemoveModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {removeOutcome} from '@canvas/outcomes/graphql/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/outcomes/graphql/Management')
class CustomError extends Error {
  constructor(message) {
    super()
    this.response = {
      data: {
        message
      }
    }
  }
}

describe('OutcomeRemoveModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    groupId: '123',
    outcomeId: '12',
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

  const render = (children, {contextType = 'Account', contextId = '1'} = {}) => {
    return rawRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    )
  }

  it('shows modal if isOpen prop true', () => {
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    expect(getByText('Remove Outcome?')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = render(<OutcomeRemoveModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Remove button click', () => {
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Outcome'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Cancel button click', () => {
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', () => {
    const {getAllByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    const closeBtn = getAllByText('Close')[getAllByText('Close').length - 1]
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('renders component with proper text for Account context', () => {
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    expect(
      getByText('Are you sure that you want to remove this outcome from this account?')
    ).toBeInTheDocument()
  })

  it('renders component with proper text for Course context', () => {
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />, {
      contextType: 'Course'
    })
    expect(
      getByText('Are you sure that you want to remove this outcome from this course?')
    ).toBeInTheDocument()
  })

  it('displays flash confirmation with proper message if delete request succeeds in Account context', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    removeOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Outcome'))
    expect(removeOutcome).toHaveBeenCalledWith('Account', '1', '123', '12')
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'This outcome was successfully removed from this account.',
        type: 'success'
      })
    })
  })

  it('displays flash confirmation with proper message if delete request succeeds in Course context', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    removeOutcome.mockReturnValue(Promise.resolve({status: 200}))
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />, {
      contextType: 'Course'
    })
    fireEvent.click(getByText('Remove Outcome'))
    expect(removeOutcome).toHaveBeenCalledWith('Course', '1', '123', '12')
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'This outcome was successfully removed from this course.',
        type: 'success'
      })
    })
  })

  it('displays flash error with proper message if delete request fails due to outcome being aligned to content', async () => {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    removeOutcome.mockReturnValue(
      Promise.reject(new CustomError('Outcome cannot be deleted because it is aligned to content'))
    )
    const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
    fireEvent.click(getByText('Remove Outcome'))
    expect(removeOutcome).toHaveBeenCalledWith('Account', '1', '123', '12')
    await waitFor(() => {
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message:
          'An error occurred while removing the outcome: Outcome cannot be removed because it is aligned to content',
        type: 'error'
      })
    })
  })
})

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext from '../contexts/OutcomesContext'

describe('FindOutcomesModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    open: true,
    onCloseHandler: onCloseHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component with "Add Outcomes to Account" title when contextType is Account', () => {
    const {getByText} = render(
      <OutcomesContext.Provider value={{env: {contextType: 'Account'}}}>
        <FindOutcomesModal {...defaultProps()} />
      </OutcomesContext.Provider>
    )
    expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
  })

  it('renders component with "Add Outcomes to Course" title when contextType is Course', () => {
    const {getByText} = render(
      <OutcomesContext.Provider value={{env: {contextType: 'Course'}}}>
        <FindOutcomesModal {...defaultProps()} />
      </OutcomesContext.Provider>
    )
    expect(getByText('Add Outcomes to Course')).toBeInTheDocument()
  })

  it('shows modal if open prop true', () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', () => {
    const {queryByText} = render(<FindOutcomesModal {...defaultProps({open: false})} />)
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Done button click', () => {
    const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
    const doneBtn = getByText('Done')
    fireEvent.click(doneBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })
})

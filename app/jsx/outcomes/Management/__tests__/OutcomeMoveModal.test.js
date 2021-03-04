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
import {render, fireEvent} from '@testing-library/react'
import MoveGroupModal from '../OutcomeMoveModal'

describe('MoveGroupModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    title: 'Outcome Group',
    type: 'outcome',
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  it('renders component with Group title', () => {
    const {getByText} = render(<MoveGroupModal {...defaultProps()} />)
    expect(getByText('Move "Outcome Group"')).toBeInTheDocument()
  })

  it('shows modal if open prop true', () => {
    const {getByText} = render(<MoveGroupModal {...defaultProps()} />)
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', () => {
    const {queryByText} = render(<MoveGroupModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Close')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', () => {
    const {getByText} = render(<MoveGroupModal {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Done button click', () => {
    const {getByText} = render(<MoveGroupModal {...defaultProps()} />)
    const doneBtn = getByText('Done')
    fireEvent.click(doneBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })
})

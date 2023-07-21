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
import GroupDescriptionModal from '../GroupDescriptionModal'

jest.mock('@canvas/outcomes/graphql/Management')

describe('GroupDescriptionModal', () => {
  let onCloseHandlerMock
  const defaultProps = (props = {}) => ({
    outcomeGroup: {
      _id: '1',
      title: 'Group Title',
      description: 'Group Description',
    },
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    ...props,
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows modal if isOpen prop true', () => {
    const {getByText} = render(<GroupDescriptionModal {...defaultProps()} />)
    expect(getByText('Group Title')).toBeInTheDocument()
  })

  it('does not show modal if isOpen prop false', () => {
    const {queryByText} = render(<GroupDescriptionModal {...defaultProps({isOpen: false})} />)
    expect(queryByText('Group Title')).not.toBeInTheDocument()
  })

  it('calls onCloseHandler on Done button click', async () => {
    const {getByText} = render(<GroupDescriptionModal {...defaultProps()} />)
    fireEvent.click(getByText('Done'))
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandler on Close (X) button click', async () => {
    const {getByText} = render(<GroupDescriptionModal {...defaultProps()} />)
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })
})
